import { ApiStatus } from '@/components/ApiStatus'
import { Button } from '@/components/ui/Button'

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-6">
            Welcome to Your App
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300 mb-8">
            Your Next.js application is ready! Start building something amazing.
          </p>
          
          <div className="space-y-4 mb-12">
            <Button href="/api/docs" variant="primary">
              View API Documentation
            </Button>
            <Button href="https://nextjs.org/docs" variant="secondary" external>
              Next.js Documentation
            </Button>
          </div>

          <ApiStatus />
        </div>
      </div>
    </main>
  )
}
