# Next.js Component Examples

This directory contains working examples for Next.js components that demonstrate best practices and common patterns.

## 📋 Available Examples

### Core Examples
- **example-basic-app.tsx** - Basic Next.js app structure with routing
- **example-api-routes.ts** - API route examples with validation
- **example-components.tsx** - Reusable component library

## 🚀 Setup Instructions

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment:**
   ```bash
   cp .env.local.example .env.local
   # Edit .env.local with your configuration
   ```

3. **Start development server:**
   ```bash
   npm run dev
   ```

4. **Open in browser:**
   ```
   http://localhost:3000
   ```

## 📖 Example Details

### example-basic-app.tsx
Demonstrates:
- App Router structure
- Layout components
- Page components
- Navigation
- Basic state management

### example-api-routes.ts
Demonstrates:
- API route handlers
- Request validation
- Response formatting
- Error handling
- CORS configuration

### example-components.tsx
Demonstrates:
- Reusable component patterns
- TypeScript interfaces
- Props validation
- Component composition
- Styling with Tailwind CSS

## 🔧 Integration with Backend

These examples are designed to work with FastAPI backends. See the `nextjs-fastapi` combination examples for full-stack integration patterns.

## 📝 Notes

- All examples use TypeScript for type safety
- Components follow Next.js 13+ App Router patterns
- Examples include proper error handling and loading states
- Tailwind CSS is used for styling