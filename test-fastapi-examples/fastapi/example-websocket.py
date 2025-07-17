"""
FastAPI WebSocket Example
WebSocket integration for real-time communication.

Features:
- WebSocket connection management
- Message broadcasting
- Connection state tracking
- Error handling for disconnections
- JSON message formatting

Setup:
1. pip install fastapi uvicorn websockets
2. uvicorn example-websocket:app --reload
3. Connect to ws://localhost:8000/ws

Usage:
- Send JSON messages: {"type": "message", "content": "Hello World"}
- Receive real-time updates from all connected clients
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.responses import HTMLResponse
from typing import List, Dict, Any
import json
import asyncio
from datetime import datetime
import uuid

# FastAPI app
app = FastAPI(
    title="WebSocket Chat API",
    description="Real-time WebSocket communication",
    version="1.0.0"
)

# Connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.user_info: Dict[str, Dict[str, Any]] = {}
    
    async def connect(self, websocket: WebSocket, client_id: str):
        """Accept websocket connection and store it"""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        self.user_info[client_id] = {
            "connected_at": datetime.utcnow(),
            "messages_sent": 0
        }
        
        # Notify all clients about new connection
        await self.broadcast_system_message(f"User {client_id} connected")
        
        # Send welcome message to new client
        await self.send_personal_message({
            "type": "system",
            "content": f"Welcome! You are connected as {client_id}",
            "timestamp": datetime.utcnow().isoformat(),
            "active_users": len(self.active_connections)
        }, client_id)
    
    def disconnect(self, client_id: str):
        """Remove connection and user info"""
        if client_id in self.active_connections:
            del self.active_connections[client_id]
        if client_id in self.user_info:
            del self.user_info[client_id]
    
    async def send_personal_message(self, message: Dict[str, Any], client_id: str):
        """Send message to specific client"""
        if client_id in self.active_connections:
            websocket = self.active_connections[client_id]
            try:
                await websocket.send_text(json.dumps(message))
            except Exception as e:
                print(f"Error sending message to {client_id}: {e}")
                # Remove broken connection
                self.disconnect(client_id)
    
    async def broadcast_message(self, message: Dict[str, Any], sender_id: str):
        """Broadcast message to all connected clients"""
        # Add sender info and timestamp
        broadcast_data = {
            **message,
            "sender_id": sender_id,
            "timestamp": datetime.utcnow().isoformat(),
            "active_users": len(self.active_connections)
        }
        
        # Update sender stats
        if sender_id in self.user_info:
            self.user_info[sender_id]["messages_sent"] += 1
        
        # Send to all connected clients
        disconnected_clients = []
        for client_id, websocket in self.active_connections.items():
            try:
                await websocket.send_text(json.dumps(broadcast_data))
            except Exception as e:
                print(f"Error broadcasting to {client_id}: {e}")
                disconnected_clients.append(client_id)
        
        # Clean up disconnected clients
        for client_id in disconnected_clients:
            self.disconnect(client_id)
    
    async def broadcast_system_message(self, content: str):
        """Broadcast system message to all clients"""
        system_message = {
            "type": "system",
            "content": content,
            "timestamp": datetime.utcnow().isoformat(),
            "active_users": len(self.active_connections)
        }
        
        disconnected_clients = []
        for client_id, websocket in self.active_connections.items():
            try:
                await websocket.send_text(json.dumps(system_message))
            except Exception as e:
                print(f"Error sending system message to {client_id}: {e}")
                disconnected_clients.append(client_id)
        
        # Clean up disconnected clients
        for client_id in disconnected_clients:
            self.disconnect(client_id)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get connection statistics"""
        return {
            "active_connections": len(self.active_connections),
            "connected_users": list(self.active_connections.keys()),
            "user_stats": self.user_info
        }

# Global connection manager
manager = ConnectionManager()

# Routes
@app.get("/", tags=["root"])
def read_root():
    """API health check"""
    return {
        "message": "WebSocket API is running",
        "websocket_url": "ws://localhost:8000/ws",
        "stats_url": "/stats",
        "test_client": "/test"
    }

@app.get("/test", response_class=HTMLResponse, tags=["test"])
async def test_client():
    """Simple WebSocket test client"""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>WebSocket Test Client</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            #messages { border: 1px solid #ccc; height: 400px; overflow-y: scroll; padding: 10px; margin: 10px 0; }
            #messageInput { width: 70%; padding: 5px; }
            #sendButton { padding: 5px 10px; }
            .message { margin: 5px 0; }
            .system { color: #666; font-style: italic; }
            .user { color: #000; }
        </style>
    </head>
    <body>
        <h1>WebSocket Test Client</h1>
        <div id="messages"></div>
        <input type="text" id="messageInput" placeholder="Type your message...">
        <button id="sendButton">Send</button>
        <button id="connectButton">Connect</button>
        <button id="disconnectButton">Disconnect</button>
        
        <script>
            let ws = null;
            const messages = document.getElementById('messages');
            const messageInput = document.getElementById('messageInput');
            const sendButton = document.getElementById('sendButton');
            const connectButton = document.getElementById('connectButton');
            const disconnectButton = document.getElementById('disconnectButton');
            
            function addMessage(message, className = 'user') {
                const div = document.createElement('div');
                div.className = `message ${className}`;
                div.textContent = message;
                messages.appendChild(div);
                messages.scrollTop = messages.scrollHeight;
            }
            
            function connect() {
                const clientId = 'user_' + Math.random().toString(36).substr(2, 9);
                ws = new WebSocket(`ws://localhost:8000/ws?client_id=${clientId}`);
                
                ws.onopen = function(event) {
                    addMessage('Connected to WebSocket', 'system');
                    connectButton.disabled = true;
                    disconnectButton.disabled = false;
                    sendButton.disabled = false;
                };
                
                ws.onmessage = function(event) {
                    const data = JSON.parse(event.data);
                    const className = data.type === 'system' ? 'system' : 'user';
                    const message = `[${data.timestamp}] ${data.sender_id || 'System'}: ${data.content}`;
                    addMessage(message, className);
                };
                
                ws.onclose = function(event) {
                    addMessage('Disconnected from WebSocket', 'system');
                    connectButton.disabled = false;
                    disconnectButton.disabled = true;
                    sendButton.disabled = true;
                };
                
                ws.onerror = function(error) {
                    addMessage('WebSocket error: ' + error, 'system');
                };
            }
            
            function disconnect() {
                if (ws) {
                    ws.close();
                }
            }
            
            function sendMessage() {
                const message = messageInput.value.trim();
                if (message && ws && ws.readyState === WebSocket.OPEN) {
                    ws.send(JSON.stringify({
                        type: 'message',
                        content: message
                    }));
                    messageInput.value = '';
                }
            }
            
            connectButton.onclick = connect;
            disconnectButton.onclick = disconnect;
            sendButton.onclick = sendMessage;
            
            messageInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    sendMessage();
                }
            });
            
            // Initial state
            disconnectButton.disabled = true;
            sendButton.disabled = true;
        </script>
    </body>
    </html>
    """

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, client_id: str = None):
    """WebSocket endpoint for real-time communication"""
    if not client_id:
        client_id = f"user_{uuid.uuid4().hex[:8]}"
    
    await manager.connect(websocket, client_id)
    
    try:
        while True:
            # Wait for message from client
            data = await websocket.receive_text()
            
            try:
                # Parse JSON message
                message = json.loads(data)
                
                # Validate message format
                if not isinstance(message, dict) or "type" not in message:
                    await manager.send_personal_message({
                        "type": "error",
                        "content": "Invalid message format. Expected JSON with 'type' field."
                    }, client_id)
                    continue
                
                # Handle different message types
                if message["type"] == "message":
                    if "content" not in message:
                        await manager.send_personal_message({
                            "type": "error",
                            "content": "Message must have 'content' field."
                        }, client_id)
                        continue
                    
                    # Broadcast user message
                    await manager.broadcast_message(message, client_id)
                
                elif message["type"] == "ping":
                    # Respond to ping
                    await manager.send_personal_message({
                        "type": "pong",
                        "content": "pong",
                        "timestamp": datetime.utcnow().isoformat()
                    }, client_id)
                
                elif message["type"] == "stats":
                    # Send connection stats
                    stats = manager.get_stats()
                    await manager.send_personal_message({
                        "type": "stats",
                        "content": stats,
                        "timestamp": datetime.utcnow().isoformat()
                    }, client_id)
                
                else:
                    await manager.send_personal_message({
                        "type": "error",
                        "content": f"Unknown message type: {message['type']}"
                    }, client_id)
                    
            except json.JSONDecodeError:
                await manager.send_personal_message({
                    "type": "error",
                    "content": "Invalid JSON format"
                }, client_id)
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)
        await manager.broadcast_system_message(f"User {client_id} disconnected")
    except Exception as e:
        print(f"WebSocket error for {client_id}: {e}")
        manager.disconnect(client_id)
        await manager.broadcast_system_message(f"User {client_id} disconnected due to error")

@app.get("/stats", tags=["stats"])
async def get_connection_stats():
    """Get current connection statistics"""
    return manager.get_stats()

@app.post("/broadcast", tags=["admin"])
async def broadcast_admin_message(message: str):
    """Broadcast admin message to all connected clients"""
    await manager.broadcast_system_message(f"Admin: {message}")
    return {"status": "Message broadcasted", "active_connections": len(manager.active_connections)}

# Error handlers
@app.exception_handler(404)
def not_found_handler(request, exc):
    return {"error": "Endpoint not found"}

@app.exception_handler(422)
def validation_exception_handler(request, exc):
    return {"error": "Validation error", "details": exc.errors()}

# Run with: uvicorn example-websocket:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)