#!/usr/bin/env python3
"""
Redis Pub/Sub Example (Python)

This example demonstrates Redis publish/subscribe functionality
for real-time messaging and event-driven architectures.
"""

import os
import sys
import json
import time
import threading
from typing import Any, Dict, List, Optional, Callable
from dataclasses import dataclass, asdict
from datetime import datetime
import redis
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

@dataclass
class Message:
    """Message data model."""
    id: str
    channel: str
    content: str
    timestamp: str
    sender: str
    message_type: str = "text"
    metadata: Optional[Dict[str, Any]] = None

class RedisPubSub:
    """Redis publish/subscribe client."""
    
    def __init__(self, 
                 host: str = None,
                 port: int = None,
                 db: int = None,
                 password: str = None):
        """Initialize Redis pub/sub client."""
        
        # Get configuration from environment variables
        self.host = host or os.getenv("REDIS_HOST", "localhost")
        self.port = port or int(os.getenv("REDIS_PORT", "6379"))
        self.db = db or int(os.getenv("REDIS_DB", "0"))
        self.password = password or os.getenv("REDIS_PASSWORD")
        
        # Redis clients (separate for pub and sub)
        self.publisher = redis.Redis(
            host=self.host,
            port=self.port,
            db=self.db,
            password=self.password,
            decode_responses=True
        )
        
        self.subscriber = redis.Redis(
            host=self.host,
            port=self.port,
            db=self.db,
            password=self.password,
            decode_responses=True
        )
        
        # Test connection
        try:
            self.publisher.ping()
            print(f"✅ Redis Pub/Sub connected at {self.host}:{self.port}")
        except redis.ConnectionError as e:
            print(f"❌ Failed to connect to Redis: {e}")
            raise
        
        # Pub/Sub object
        self.pubsub = self.subscriber.pubsub()
        
        # Message handlers
        self.message_handlers: Dict[str, List[Callable]] = {}
        self.is_listening = False
        self.listener_thread = None
    
    def publish(self, channel: str, message: Any) -> int:
        """Publish a message to a channel."""
        try:
            # Serialize message if it's not a string
            if not isinstance(message, str):
                message = json.dumps(message)
            
            # Publish message
            subscriber_count = self.publisher.publish(channel, message)
            
            print(f"📡 Published to {channel}: {subscriber_count} subscribers")
            return subscriber_count
            
        except Exception as e:
            print(f"❌ Error publishing to {channel}: {e}")
            return 0
    
    def subscribe(self, *channels: str) -> bool:
        """Subscribe to one or more channels."""
        try:
            self.pubsub.subscribe(*channels)
            print(f"🔔 Subscribed to channels: {', '.join(channels)}")
            return True
            
        except Exception as e:
            print(f"❌ Error subscribing to channels: {e}")
            return False
    
    def unsubscribe(self, *channels: str) -> bool:
        """Unsubscribe from one or more channels."""
        try:
            self.pubsub.unsubscribe(*channels)
            print(f"🔕 Unsubscribed from channels: {', '.join(channels)}")
            return True
            
        except Exception as e:
            print(f"❌ Error unsubscribing from channels: {e}")
            return False
    
    def pattern_subscribe(self, *patterns: str) -> bool:
        """Subscribe to channel patterns."""
        try:
            self.pubsub.psubscribe(*patterns)
            print(f"🔔 Subscribed to patterns: {', '.join(patterns)}")
            return True
            
        except Exception as e:
            print(f"❌ Error subscribing to patterns: {e}")
            return False
    
    def add_message_handler(self, channel: str, handler: Callable[[str, Any], None]):
        """Add a message handler for a specific channel."""
        if channel not in self.message_handlers:
            self.message_handlers[channel] = []
        
        self.message_handlers[channel].append(handler)
        print(f"🔧 Added message handler for {channel}")
    
    def remove_message_handler(self, channel: str, handler: Callable[[str, Any], None]):
        """Remove a message handler for a specific channel."""
        if channel in self.message_handlers:
            try:
                self.message_handlers[channel].remove(handler)
                print(f"🔧 Removed message handler for {channel}")
            except ValueError:
                print(f"⚠️ Handler not found for {channel}")
    
    def start_listening(self):
        """Start listening for messages in a separate thread."""
        if self.is_listening:
            print("⚠️ Already listening for messages")
            return
        
        self.is_listening = True
        self.listener_thread = threading.Thread(target=self._listen_for_messages, daemon=True)
        self.listener_thread.start()
        print("🎧 Started listening for messages")
    
    def stop_listening(self):
        """Stop listening for messages."""
        if not self.is_listening:
            print("⚠️ Not currently listening")
            return
        
        self.is_listening = False
        if self.listener_thread:
            self.listener_thread.join(timeout=1)
        
        print("🛑 Stopped listening for messages")
    
    def _listen_for_messages(self):
        """Listen for messages (runs in separate thread)."""
        try:
            for message in self.pubsub.listen():
                if not self.is_listening:
                    break
                
                # Handle different message types
                if message['type'] == 'message':
                    self._handle_message(message['channel'], message['data'])
                elif message['type'] == 'pmessage':
                    self._handle_pattern_message(message['pattern'], message['channel'], message['data'])
                elif message['type'] == 'subscribe':
                    print(f"✅ Subscribed to {message['channel']}")
                elif message['type'] == 'unsubscribe':
                    print(f"❌ Unsubscribed from {message['channel']}")
                elif message['type'] == 'psubscribe':
                    print(f"✅ Pattern subscribed to {message['pattern']}")
                elif message['type'] == 'punsubscribe':
                    print(f"❌ Pattern unsubscribed from {message['pattern']}")
        
        except Exception as e:
            print(f"❌ Error in message listener: {e}")
    
    def _handle_message(self, channel: str, data: str):
        """Handle a regular message."""
        try:
            # Try to parse as JSON
            try:
                message_data = json.loads(data)
            except json.JSONDecodeError:
                message_data = data
            
            # Call handlers for this channel
            if channel in self.message_handlers:
                for handler in self.message_handlers[channel]:
                    try:
                        handler(channel, message_data)
                    except Exception as e:
                        print(f"❌ Error in message handler for {channel}: {e}")
            
            # Default handler
            print(f"📨 {channel}: {message_data}")
            
        except Exception as e:
            print(f"❌ Error handling message: {e}")
    
    def _handle_pattern_message(self, pattern: str, channel: str, data: str):
        """Handle a pattern message."""
        try:
            # Try to parse as JSON
            try:
                message_data = json.loads(data)
            except json.JSONDecodeError:
                message_data = data
            
            print(f"📨 Pattern {pattern} -> {channel}: {message_data}")
            
        except Exception as e:
            print(f"❌ Error handling pattern message: {e}")
    
    def get_subscribers_count(self, channel: str) -> int:
        """Get number of subscribers for a channel."""
        try:
            result = self.publisher.pubsub_numsub(channel)
            return result[0][1] if result else 0
        except Exception as e:
            print(f"❌ Error getting subscriber count: {e}")
            return 0
    
    def get_active_channels(self) -> List[str]:
        """Get list of active channels."""
        try:
            return self.publisher.pubsub_channels()
        except Exception as e:
            print(f"❌ Error getting active channels: {e}")
            return []

class ChatRoom:
    """Chat room implementation using Redis pub/sub."""
    
    def __init__(self, room_name: str):
        """Initialize chat room."""
        self.room_name = room_name
        self.channel = f"chat:{room_name}"
        self.pubsub = RedisPubSub()
        self.users: Dict[str, datetime] = {}
        
        # Add message handler
        self.pubsub.add_message_handler(self.channel, self._handle_chat_message)
        
        # Subscribe to chat channel
        self.pubsub.subscribe(self.channel)
    
    def join(self, username: str):
        """Join the chat room."""
        self.users[username] = datetime.now()
        
        # Send join message
        join_message = Message(
            id=f"join_{int(time.time())}",
            channel=self.channel,
            content=f"{username} joined the room",
            timestamp=datetime.now().isoformat(),
            sender="system",
            message_type="join"
        )
        
        self.pubsub.publish(self.channel, asdict(join_message))
        print(f"👋 {username} joined {self.room_name}")
    
    def leave(self, username: str):
        """Leave the chat room."""
        if username in self.users:
            del self.users[username]
            
            # Send leave message
            leave_message = Message(
                id=f"leave_{int(time.time())}",
                channel=self.channel,
                content=f"{username} left the room",
                timestamp=datetime.now().isoformat(),
                sender="system",
                message_type="leave"
            )
            
            self.pubsub.publish(self.channel, asdict(leave_message))
            print(f"👋 {username} left {self.room_name}")
    
    def send_message(self, sender: str, content: str):
        """Send a chat message."""
        message = Message(
            id=f"msg_{int(time.time())}",
            channel=self.channel,
            content=content,
            timestamp=datetime.now().isoformat(),
            sender=sender,
            message_type="chat"
        )
        
        self.pubsub.publish(self.channel, asdict(message))
    
    def _handle_chat_message(self, channel: str, data: Dict[str, Any]):
        """Handle chat messages."""
        try:
            message = Message(**data)
            
            if message.message_type == "chat":
                print(f"💬 [{message.sender}]: {message.content}")
            elif message.message_type == "join":
                print(f"✅ {message.content}")
            elif message.message_type == "leave":
                print(f"❌ {message.content}")
            
        except Exception as e:
            print(f"❌ Error handling chat message: {e}")
    
    def start_listening(self):
        """Start listening for chat messages."""
        self.pubsub.start_listening()
    
    def stop_listening(self):
        """Stop listening for chat messages."""
        self.pubsub.stop_listening()

class EventBus:
    """Event bus implementation using Redis pub/sub."""
    
    def __init__(self):
        """Initialize event bus."""
        self.pubsub = RedisPubSub()
        self.event_handlers: Dict[str, List[Callable]] = {}
    
    def subscribe_to_event(self, event_type: str, handler: Callable[[Dict[str, Any]], None]):
        """Subscribe to an event type."""
        channel = f"events:{event_type}"
        
        if event_type not in self.event_handlers:
            self.event_handlers[event_type] = []
            self.pubsub.subscribe(channel)
        
        self.event_handlers[event_type].append(handler)
        self.pubsub.add_message_handler(channel, lambda ch, data: self._handle_event(event_type, data))
    
    def publish_event(self, event_type: str, event_data: Dict[str, Any]):
        """Publish an event."""
        channel = f"events:{event_type}"
        
        event = {
            "type": event_type,
            "data": event_data,
            "timestamp": datetime.now().isoformat(),
            "id": f"event_{int(time.time())}"
        }
        
        self.pubsub.publish(channel, event)
    
    def _handle_event(self, event_type: str, data: Dict[str, Any]):
        """Handle events."""
        if event_type in self.event_handlers:
            for handler in self.event_handlers[event_type]:
                try:
                    handler(data)
                except Exception as e:
                    print(f"❌ Error in event handler for {event_type}: {e}")
    
    def start_listening(self):
        """Start listening for events."""
        self.pubsub.start_listening()
    
    def stop_listening(self):
        """Stop listening for events."""
        self.pubsub.stop_listening()

def main():
    """Main function demonstrating Redis pub/sub."""
    print("📡 Redis Pub/Sub Example (Python)")
    print("=" * 50)
    
    try:
        # Initialize pub/sub
        pubsub = RedisPubSub()
        
        # Demo 1: Basic pub/sub
        print("\n🔔 Basic Pub/Sub Demo")
        print("-" * 30)
        
        # Subscribe to channels
        pubsub.subscribe("news", "alerts")
        pubsub.start_listening()
        
        # Give it a moment to start
        time.sleep(1)
        
        # Publish some messages
        pubsub.publish("news", "Breaking: Redis pub/sub working!")
        pubsub.publish("alerts", "System maintenance in 1 hour")
        pubsub.publish("news", {"headline": "JSON message test", "priority": "high"})
        
        time.sleep(2)
        
        # Demo 2: Chat room
        print("\n💬 Chat Room Demo")
        print("-" * 30)
        
        chat_room = ChatRoom("general")
        chat_room.start_listening()
        
        # Simulate chat activity
        chat_room.join("alice")
        time.sleep(1)
        chat_room.join("bob")
        time.sleep(1)
        
        chat_room.send_message("alice", "Hello everyone!")
        time.sleep(1)
        chat_room.send_message("bob", "Hi Alice! How are you?")
        time.sleep(1)
        chat_room.send_message("alice", "I'm doing great, thanks!")
        
        time.sleep(2)
        
        # Demo 3: Event bus
        print("\n🚌 Event Bus Demo")
        print("-" * 30)
        
        event_bus = EventBus()
        
        # Subscribe to events
        def handle_user_signup(event_data):
            print(f"🆕 New user signup: {event_data['data']['username']}")
        
        def handle_order_placed(event_data):
            print(f"🛒 Order placed: ${event_data['data']['amount']} by {event_data['data']['customer']}")
        
        event_bus.subscribe_to_event("user_signup", handle_user_signup)
        event_bus.subscribe_to_event("order_placed", handle_order_placed)
        event_bus.start_listening()
        
        time.sleep(1)
        
        # Publish events
        event_bus.publish_event("user_signup", {"username": "john_doe", "email": "john@example.com"})
        event_bus.publish_event("order_placed", {"customer": "alice", "amount": 49.99, "items": 3})
        
        time.sleep(2)
        
        # Interactive mode
        print("\n" + "=" * 50)
        print("🎯 Interactive Pub/Sub Demo")
        print("Commands:")
        print("  'sub <channel>' - Subscribe to channel")
        print("  'unsub <channel>' - Unsubscribe from channel")
        print("  'pub <channel> <message>' - Publish message")
        print("  'psub <pattern>' - Subscribe to pattern")
        print("  'count <channel>' - Get subscriber count")
        print("  'channels' - List active channels")
        print("  'quit' - Exit")
        print("-" * 50)
        
        while True:
            user_input = input("\n📡 PubSub> ").strip()
            
            if user_input.lower() == 'quit':
                print("👋 Goodbye!")
                break
            elif user_input.startswith('sub '):
                channel = user_input.split(' ', 1)[1]
                pubsub.subscribe(channel)
            elif user_input.startswith('unsub '):
                channel = user_input.split(' ', 1)[1]
                pubsub.unsubscribe(channel)
            elif user_input.startswith('pub '):
                parts = user_input.split(' ', 2)
                if len(parts) >= 3:
                    channel, message = parts[1], parts[2]
                    pubsub.publish(channel, message)
                else:
                    print("Usage: pub <channel> <message>")
            elif user_input.startswith('psub '):
                pattern = user_input.split(' ', 1)[1]
                pubsub.pattern_subscribe(pattern)
            elif user_input.startswith('count '):
                channel = user_input.split(' ', 1)[1]
                count = pubsub.get_subscribers_count(channel)
                print(f"👥 {channel}: {count} subscribers")
            elif user_input.lower() == 'channels':
                channels = pubsub.get_active_channels()
                print(f"📺 Active channels: {', '.join(channels) if channels else 'None'}")
            elif user_input:
                print("Unknown command. Type 'quit' to exit.")
        
        # Cleanup
        pubsub.stop_listening()
        chat_room.stop_listening()
        event_bus.stop_listening()
        
    except KeyboardInterrupt:
        print("\n\n👋 Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()