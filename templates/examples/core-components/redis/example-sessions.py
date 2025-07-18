#!/usr/bin/env python3
"""
Redis Session Management Example (Python)

This example demonstrates how to use Redis for session management
with proper serialization, expiration, and session handling.
"""

import os
import sys
import json
import uuid
from typing import Any, Optional, Dict, List
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
import redis
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

@dataclass
class User:
    """User data model."""
    id: str
    username: str
    email: str
    role: str
    created_at: str
    last_login: Optional[str] = None

@dataclass
class Session:
    """Session data model."""
    session_id: str
    user_id: str
    username: str
    created_at: str
    last_activity: str
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    data: Optional[Dict[str, Any]] = None

class SessionManager:
    """Redis-based session management system."""
    
    def __init__(self, 
                 host: str = None,
                 port: int = None,
                 db: int = None,
                 password: str = None,
                 session_ttl: int = 3600):  # 1 hour default
        """Initialize the session manager."""
        
        # Get configuration from environment variables
        self.host = host or os.getenv("REDIS_HOST", "localhost")
        self.port = port or int(os.getenv("REDIS_PORT", "6379"))
        self.db = db or int(os.getenv("REDIS_DB", "0"))
        self.password = password or os.getenv("REDIS_PASSWORD")
        self.session_ttl = session_ttl
        
        # Redis client
        self.client = redis.Redis(
            host=self.host,
            port=self.port,
            db=self.db,
            password=self.password,
            decode_responses=True
        )
        
        # Test connection
        try:
            self.client.ping()
            print(f"✅ Session manager connected to Redis at {self.host}:{self.port}")
        except redis.ConnectionError as e:
            print(f"❌ Failed to connect to Redis: {e}")
            raise
        
        # Key prefixes
        self.SESSION_PREFIX = "session:"
        self.USER_SESSIONS_PREFIX = "user_sessions:"
        self.ACTIVE_SESSIONS_SET = "active_sessions"
    
    def create_session(self, user: User, ip_address: str = None, user_agent: str = None) -> str:
        """Create a new session for a user."""
        try:
            # Generate session ID
            session_id = str(uuid.uuid4())
            
            # Create session object
            session = Session(
                session_id=session_id,
                user_id=user.id,
                username=user.username,
                created_at=datetime.now().isoformat(),
                last_activity=datetime.now().isoformat(),
                ip_address=ip_address,
                user_agent=user_agent,
                data={}
            )
            
            # Store session
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            session_data = asdict(session)
            
            # Set session with TTL
            self.client.setex(session_key, self.session_ttl, json.dumps(session_data))
            
            # Track user sessions
            user_sessions_key = f"{self.USER_SESSIONS_PREFIX}{user.id}"
            self.client.sadd(user_sessions_key, session_id)
            self.client.expire(user_sessions_key, self.session_ttl)
            
            # Add to active sessions set
            self.client.sadd(self.ACTIVE_SESSIONS_SET, session_id)
            
            print(f"✅ Created session {session_id} for user {user.username}")
            return session_id
            
        except Exception as e:
            print(f"❌ Error creating session: {e}")
            return None
    
    def get_session(self, session_id: str) -> Optional[Session]:
        """Get session by ID."""
        try:
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            session_data = self.client.get(session_key)
            
            if not session_data:
                return None
            
            # Parse session data
            session_dict = json.loads(session_data)
            session = Session(**session_dict)
            
            # Update last activity
            session.last_activity = datetime.now().isoformat()
            self.client.setex(session_key, self.session_ttl, json.dumps(asdict(session)))
            
            return session
            
        except Exception as e:
            print(f"❌ Error getting session {session_id}: {e}")
            return None
    
    def update_session(self, session_id: str, data: Dict[str, Any]) -> bool:
        """Update session data."""
        try:
            session = self.get_session(session_id)
            if not session:
                return False
            
            # Update session data
            if session.data:
                session.data.update(data)
            else:
                session.data = data
            
            session.last_activity = datetime.now().isoformat()
            
            # Save updated session
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            self.client.setex(session_key, self.session_ttl, json.dumps(asdict(session)))
            
            return True
            
        except Exception as e:
            print(f"❌ Error updating session {session_id}: {e}")
            return False
    
    def delete_session(self, session_id: str) -> bool:
        """Delete a session."""
        try:
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            
            # Get session first to find user ID
            session = self.get_session(session_id)
            if session:
                # Remove from user sessions
                user_sessions_key = f"{self.USER_SESSIONS_PREFIX}{session.user_id}"
                self.client.srem(user_sessions_key, session_id)
            
            # Remove from active sessions
            self.client.srem(self.ACTIVE_SESSIONS_SET, session_id)
            
            # Delete session
            result = self.client.delete(session_key)
            
            if result:
                print(f"✅ Deleted session {session_id}")
            
            return bool(result)
            
        except Exception as e:
            print(f"❌ Error deleting session {session_id}: {e}")
            return False
    
    def get_user_sessions(self, user_id: str) -> List[Session]:
        """Get all sessions for a user."""
        try:
            user_sessions_key = f"{self.USER_SESSIONS_PREFIX}{user_id}"
            session_ids = self.client.smembers(user_sessions_key)
            
            sessions = []
            for session_id in session_ids:
                session = self.get_session(session_id)
                if session:
                    sessions.append(session)
            
            return sessions
            
        except Exception as e:
            print(f"❌ Error getting user sessions for {user_id}: {e}")
            return []
    
    def delete_user_sessions(self, user_id: str) -> int:
        """Delete all sessions for a user."""
        try:
            sessions = self.get_user_sessions(user_id)
            deleted_count = 0
            
            for session in sessions:
                if self.delete_session(session.session_id):
                    deleted_count += 1
            
            # Clean up user sessions key
            user_sessions_key = f"{self.USER_SESSIONS_PREFIX}{user_id}"
            self.client.delete(user_sessions_key)
            
            print(f"✅ Deleted {deleted_count} sessions for user {user_id}")
            return deleted_count
            
        except Exception as e:
            print(f"❌ Error deleting user sessions for {user_id}: {e}")
            return 0
    
    def get_active_sessions_count(self) -> int:
        """Get count of active sessions."""
        try:
            return self.client.scard(self.ACTIVE_SESSIONS_SET)
        except Exception as e:
            print(f"❌ Error getting active sessions count: {e}")
            return 0
    
    def cleanup_expired_sessions(self) -> int:
        """Clean up expired sessions from tracking sets."""
        try:
            active_session_ids = self.client.smembers(self.ACTIVE_SESSIONS_SET)
            expired_count = 0
            
            for session_id in active_session_ids:
                session_key = f"{self.SESSION_PREFIX}{session_id}"
                if not self.client.exists(session_key):
                    # Session expired, remove from tracking
                    self.client.srem(self.ACTIVE_SESSIONS_SET, session_id)
                    expired_count += 1
            
            print(f"🧹 Cleaned up {expired_count} expired sessions")
            return expired_count
            
        except Exception as e:
            print(f"❌ Error cleaning up expired sessions: {e}")
            return 0
    
    def get_session_stats(self) -> Dict[str, Any]:
        """Get session statistics."""
        try:
            stats = {
                "active_sessions": self.get_active_sessions_count(),
                "session_ttl": self.session_ttl,
                "redis_info": {
                    "used_memory": self.client.info()["used_memory_human"],
                    "connected_clients": self.client.info()["connected_clients"]
                }
            }
            
            return stats
            
        except Exception as e:
            print(f"❌ Error getting session stats: {e}")
            return {}

class SessionDemo:
    """Demonstration of Redis session management."""
    
    def __init__(self):
        """Initialize the session demo."""
        self.session_manager = SessionManager()
        
        # Sample users
        self.users = {
            "user1": User(
                id="user1",
                username="alice",
                email="alice@example.com",
                role="admin",
                created_at=datetime.now().isoformat()
            ),
            "user2": User(
                id="user2",
                username="bob",
                email="bob@example.com",
                role="user",
                created_at=datetime.now().isoformat()
            ),
            "user3": User(
                id="user3",
                username="charlie",
                email="charlie@example.com",
                role="user",
                created_at=datetime.now().isoformat()
            )
        }
        
        self.active_sessions = {}
    
    def login_user(self, username: str, ip_address: str = "127.0.0.1") -> Optional[str]:
        """Simulate user login."""
        user = None
        for u in self.users.values():
            if u.username == username:
                user = u
                break
        
        if not user:
            print(f"❌ User {username} not found")
            return None
        
        # Create session
        session_id = self.session_manager.create_session(
            user=user,
            ip_address=ip_address,
            user_agent="Demo Client/1.0"
        )
        
        if session_id:
            self.active_sessions[session_id] = user
            print(f"🔐 User {username} logged in with session {session_id}")
        
        return session_id
    
    def logout_user(self, session_id: str) -> bool:
        """Simulate user logout."""
        if session_id in self.active_sessions:
            user = self.active_sessions[session_id]
            if self.session_manager.delete_session(session_id):
                del self.active_sessions[session_id]
                print(f"🚪 User {user.username} logged out")
                return True
        
        print(f"❌ Session {session_id} not found")
        return False
    
    def session_activity(self, session_id: str, activity_data: Dict[str, Any]) -> bool:
        """Simulate session activity."""
        if session_id not in self.active_sessions:
            print(f"❌ Session {session_id} not active")
            return False
        
        # Update session with activity data
        success = self.session_manager.update_session(session_id, activity_data)
        if success:
            print(f"📝 Session {session_id} activity updated")
        
        return success
    
    def demo_multiple_sessions(self):
        """Demonstrate multiple session management."""
        print("\n👥 Multiple Session Management Demo")
        print("-" * 50)
        
        # Login multiple users
        sessions = []
        for username in ["alice", "bob", "charlie"]:
            session_id = self.login_user(username)
            if session_id:
                sessions.append(session_id)
        
        # Simulate activity
        for i, session_id in enumerate(sessions):
            activity = {
                "page_views": i + 1,
                "last_page": f"/dashboard/{i}",
                "actions": ["view", "edit", "save"][:i+1]
            }
            self.session_activity(session_id, activity)
        
        # Show session stats
        stats = self.session_manager.get_session_stats()
        print(f"\n📊 Session Statistics:")
        for key, value in stats.items():
            print(f"  {key}: {value}")
        
        # Show user sessions
        for user_id in ["user1", "user2"]:
            user_sessions = self.session_manager.get_user_sessions(user_id)
            print(f"\n👤 Sessions for {user_id}:")
            for session in user_sessions:
                print(f"  - {session.session_id}: {session.username} (last: {session.last_activity})")
        
        return sessions
    
    def demo_session_cleanup(self):
        """Demonstrate session cleanup."""
        print("\n🧹 Session Cleanup Demo")
        print("-" * 50)
        
        # Show current active sessions
        active_count = self.session_manager.get_active_sessions_count()
        print(f"Active sessions before cleanup: {active_count}")
        
        # Clean up expired sessions
        expired_count = self.session_manager.cleanup_expired_sessions()
        
        # Show after cleanup
        active_count_after = self.session_manager.get_active_sessions_count()
        print(f"Active sessions after cleanup: {active_count_after}")
        
        return expired_count

def main():
    """Main function demonstrating Redis session management."""
    print("🔐 Redis Session Management Example (Python)")
    print("=" * 60)
    
    try:
        # Initialize demo
        demo = SessionDemo()
        
        # Demo multiple sessions
        sessions = demo.demo_multiple_sessions()
        
        # Demo session cleanup
        demo.demo_session_cleanup()
        
        # Interactive session management
        print("\n" + "=" * 60)
        print("🎯 Interactive Session Management")
        print("Commands:")
        print("  'login <username>' - Login user")
        print("  'logout <session_id>' - Logout session")
        print("  'get <session_id>' - Get session info")
        print("  'update <session_id> <key> <value>' - Update session data")
        print("  'user <user_id>' - Show user sessions")
        print("  'stats' - Show session statistics")
        print("  'cleanup' - Clean up expired sessions")
        print("  'clear' - Clear all sessions")
        print("  'quit' - Exit")
        print("-" * 60)
        
        while True:
            user_input = input("\n📱 Session> ").strip()
            
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.lower() == 'stats':
                stats = demo.session_manager.get_session_stats()
                print("📊 Session Statistics:")
                for key, value in stats.items():
                    print(f"  {key}: {value}")
            elif user_input.lower() == 'cleanup':
                expired = demo.demo_session_cleanup()
                print(f"🧹 Cleaned up {expired} expired sessions")
            elif user_input.lower() == 'clear':
                # Clear all active sessions
                for session_id in list(demo.active_sessions.keys()):
                    demo.logout_user(session_id)
                print("🗑️ All sessions cleared")
            elif user_input.startswith('login '):
                username = user_input.split(' ', 1)[1]
                session_id = demo.login_user(username)
                if session_id:
                    print(f"✅ Login successful: {session_id}")
            elif user_input.startswith('logout '):
                session_id = user_input.split(' ', 1)[1]
                success = demo.logout_user(session_id)
                if success:
                    print("✅ Logout successful")
            elif user_input.startswith('get '):
                session_id = user_input.split(' ', 1)[1]
                session = demo.session_manager.get_session(session_id)
                if session:
                    print(f"📄 Session: {session.username} (last: {session.last_activity})")
                    if session.data:
                        print(f"  Data: {session.data}")
                else:
                    print("❌ Session not found")
            elif user_input.startswith('update '):
                parts = user_input.split(' ', 3)
                if len(parts) >= 4:
                    session_id, key, value = parts[1], parts[2], parts[3]
                    success = demo.session_manager.update_session(session_id, {key: value})
                    if success:
                        print("✅ Session updated")
                else:
                    print("Usage: update <session_id> <key> <value>")
            elif user_input.startswith('user '):
                user_id = user_input.split(' ', 1)[1]
                sessions = demo.session_manager.get_user_sessions(user_id)
                if sessions:
                    print(f"👤 Sessions for {user_id}:")
                    for session in sessions:
                        print(f"  - {session.session_id}: {session.username}")
                else:
                    print(f"❌ No sessions found for {user_id}")
            elif user_input:
                print("Unknown command. Type 'quit' to exit.")
        
    except KeyboardInterrupt:
        print("\n\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()