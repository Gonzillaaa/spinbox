import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

/**
 * Example: Next.js API Routes
 * 
 * This example demonstrates:
 * - API route handlers
 * - Request validation with Zod
 * - Response formatting
 * - Error handling
 * - CORS configuration
 * 
 * Usage:
 * Copy these route handlers to your Next.js app/api directory.
 */

// Types and Schemas
const UserSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email address'),
  age: z.number().min(0, 'Age must be positive').optional(),
});

const UpdateUserSchema = UserSchema.partial();

type User = z.infer<typeof UserSchema>;

// Mock database (replace with real database)
let users: (User & { id: string })[] = [
  { id: '1', name: 'John Doe', email: 'john@example.com', age: 30 },
  { id: '2', name: 'Jane Smith', email: 'jane@example.com', age: 25 },
];

// Helper function for CORS
function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

// Helper function for error responses
function errorResponse(message: string, status: number = 400) {
  return NextResponse.json(
    { error: message },
    { status, headers: corsHeaders() }
  );
}

// Helper function for success responses
function successResponse(data: any, status: number = 200) {
  return NextResponse.json(
    data,
    { status, headers: corsHeaders() }
  );
}

/**
 * GET /api/users
 * Retrieve all users with optional filtering
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    const limit = searchParams.get('limit');
    const offset = searchParams.get('offset');

    let filteredUsers = users;

    // Apply search filter
    if (search) {
      filteredUsers = users.filter(user =>
        user.name.toLowerCase().includes(search.toLowerCase()) ||
        user.email.toLowerCase().includes(search.toLowerCase())
      );
    }

    // Apply pagination
    if (offset) {
      const offsetNum = parseInt(offset, 10);
      filteredUsers = filteredUsers.slice(offsetNum);
    }

    if (limit) {
      const limitNum = parseInt(limit, 10);
      filteredUsers = filteredUsers.slice(0, limitNum);
    }

    return successResponse({
      users: filteredUsers,
      total: users.length,
      filtered: filteredUsers.length,
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    return errorResponse('Failed to fetch users', 500);
  }
}

/**
 * POST /api/users
 * Create a new user
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validate request body
    const validationResult = UserSchema.safeParse(body);
    if (!validationResult.success) {
      return errorResponse(
        validationResult.error.errors.map(e => e.message).join(', ')
      );
    }

    const userData = validationResult.data;

    // Check if user already exists
    const existingUser = users.find(user => user.email === userData.email);
    if (existingUser) {
      return errorResponse('User with this email already exists', 409);
    }

    // Create new user
    const newUser = {
      id: Date.now().toString(),
      ...userData,
    };

    users.push(newUser);

    return successResponse(newUser, 201);
  } catch (error) {
    console.error('Error creating user:', error);
    return errorResponse('Failed to create user', 500);
  }
}

/**
 * GET /api/users/[id]
 * Retrieve a specific user by ID
 */
export async function GET_USER_BY_ID(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    
    const user = users.find(u => u.id === id);
    if (!user) {
      return errorResponse('User not found', 404);
    }

    return successResponse(user);
  } catch (error) {
    console.error('Error fetching user:', error);
    return errorResponse('Failed to fetch user', 500);
  }
}

/**
 * PUT /api/users/[id]
 * Update a specific user by ID
 */
export async function PUT_USER_BY_ID(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const body = await request.json();
    
    // Validate request body
    const validationResult = UpdateUserSchema.safeParse(body);
    if (!validationResult.success) {
      return errorResponse(
        validationResult.error.errors.map(e => e.message).join(', ')
      );
    }

    const userData = validationResult.data;

    // Find user
    const userIndex = users.findIndex(u => u.id === id);
    if (userIndex === -1) {
      return errorResponse('User not found', 404);
    }

    // Check email uniqueness if email is being updated
    if (userData.email && userData.email !== users[userIndex].email) {
      const existingUser = users.find(user => user.email === userData.email);
      if (existingUser) {
        return errorResponse('User with this email already exists', 409);
      }
    }

    // Update user
    users[userIndex] = {
      ...users[userIndex],
      ...userData,
    };

    return successResponse(users[userIndex]);
  } catch (error) {
    console.error('Error updating user:', error);
    return errorResponse('Failed to update user', 500);
  }
}

/**
 * DELETE /api/users/[id]
 * Delete a specific user by ID
 */
export async function DELETE_USER_BY_ID(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    
    const userIndex = users.findIndex(u => u.id === id);
    if (userIndex === -1) {
      return errorResponse('User not found', 404);
    }

    const deletedUser = users.splice(userIndex, 1)[0];

    return successResponse({
      message: 'User deleted successfully',
      user: deletedUser,
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    return errorResponse('Failed to delete user', 500);
  }
}

/**
 * OPTIONS handler for CORS preflight requests
 */
export async function OPTIONS() {
  return new Response(null, {
    status: 200,
    headers: corsHeaders(),
  });
}

/**
 * Health check endpoint
 * GET /api/health
 */
export async function HEALTH_CHECK() {
  return successResponse({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
  });
}

/**
 * Example of file upload handler
 * POST /api/upload
 */
export async function UPLOAD_FILE(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;
    
    if (!file) {
      return errorResponse('No file uploaded');
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    if (!allowedTypes.includes(file.type)) {
      return errorResponse('Invalid file type. Only JPEG, PNG, and GIF are allowed');
    }

    // Validate file size (5MB limit)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      return errorResponse('File too large. Maximum size is 5MB');
    }

    // In a real application, you would upload to a cloud storage service
    // For this example, we'll just return file info
    const fileInfo = {
      name: file.name,
      size: file.size,
      type: file.type,
      uploadedAt: new Date().toISOString(),
    };

    return successResponse({
      message: 'File uploaded successfully',
      file: fileInfo,
    });
  } catch (error) {
    console.error('Error uploading file:', error);
    return errorResponse('Failed to upload file', 500);
  }
}

/**
 * Example of middleware-like functionality
 * Rate limiting example
 */
const rateLimitMap = new Map<string, { count: number; lastReset: number }>();

export function rateLimit(request: NextRequest, maxRequests: number = 100, windowMs: number = 60000) {
  const clientIP = request.ip || request.headers.get('x-forwarded-for') || 'unknown';
  const now = Date.now();
  
  let clientData = rateLimitMap.get(clientIP);
  
  if (!clientData) {
    clientData = { count: 0, lastReset: now };
    rateLimitMap.set(clientIP, clientData);
  }
  
  // Reset counter if window has expired
  if (now - clientData.lastReset > windowMs) {
    clientData.count = 0;
    clientData.lastReset = now;
  }
  
  clientData.count++;
  
  return clientData.count <= maxRequests;
}

/**
 * Example of API route with rate limiting
 * GET /api/limited
 */
export async function RATE_LIMITED_ENDPOINT(request: NextRequest) {
  if (!rateLimit(request)) {
    return errorResponse('Too many requests. Please try again later.', 429);
  }

  return successResponse({
    message: 'Request successful',
    timestamp: new Date().toISOString(),
  });
}

// Export all handlers for easy import
export {
  GET,
  POST,
  GET_USER_BY_ID,
  PUT_USER_BY_ID,
  DELETE_USER_BY_ID,
  OPTIONS,
  HEALTH_CHECK,
  UPLOAD_FILE,
  RATE_LIMITED_ENDPOINT,
};