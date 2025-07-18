'use client'

import { useEffect, useState } from 'react'

interface ApiStatusProps {
  className?: string
}

interface HealthStatus {
  status: string
  service?: string
  timestamp?: string
}

export function ApiStatus({ className }: ApiStatusProps) {
  const [backendStatus, setBackendStatus] = useState<HealthStatus | null>(null)
  const [frontendStatus, setFrontendStatus] = useState<HealthStatus | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const checkStatus = async () => {
      try {
        // Check frontend health
        const frontendResponse = await fetch('/api/health')
        const frontendData = await frontendResponse.json()
        setFrontendStatus(frontendData)

        // Check backend health
        try {
          const backendResponse = await fetch('/api/health', {
            headers: { 'X-Proxy-To': 'backend' }
          })
          const backendData = await backendResponse.json()
          setBackendStatus(backendData)
        } catch (error) {
          setBackendStatus({ status: 'error' })
        }
      } catch (error) {
        setFrontendStatus({ status: 'error' })
      } finally {
        setLoading(false)
      }
    }

    checkStatus()
  }, [])

  if (loading) {
    return (
      <div className={`text-center ${className}`}>
        <div className="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
        <p className="mt-2 text-sm text-gray-500">Checking service status...</p>
      </div>
    )
  }

  return (
    <div className={`space-y-4 ${className}`}>
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
        Service Status
      </h3>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full ${
              frontendStatus?.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'
            }`} />
            <span className="font-medium">Frontend</span>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            Status: {frontendStatus?.status || 'Unknown'}
          </p>
        </div>
        
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full ${
              backendStatus?.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'
            }`} />
            <span className="font-medium">Backend</span>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            Status: {backendStatus?.status || 'Unavailable'}
          </p>
        </div>
      </div>
    </div>
  )
}
