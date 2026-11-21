import { useEffect, useState } from 'react'

import type { AuthSession } from '@/features/auth/domain/session'
import {
  getSession,
  onAuthStateChange,
  setActiveWorkspace,
  signInWithPassword,
  signOut,
  signUpWithPassword,
} from '@/features/auth/services/authService'

export function useAuth() {
  const [session, setSession] = useState<AuthSession | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false

    void getSession().then(({ data, error: failure }) => {
      if (cancelled) return
      if (failure) setError(failure.message)
      setSession(data)
      setIsLoading(false)
    })

    const unsubscribe = onAuthStateChange((next) => {
      if (!cancelled) setSession(next)
    })

    return () => {
      cancelled = true
      unsubscribe()
    }
  }, [])

  const login = async (email: string, password: string) => {
    setError(null)
    const { data, error: failure } = await signInWithPassword(email, password)
    if (failure) {
      setError(failure.message)
      return false
    }
    setSession(data)
    return true
  }

  const register = async (
    email: string,
    password: string,
    fullName: string,
  ) => {
    setError(null)
    const { data, error: failure } = await signUpWithPassword(
      email,
      password,
      fullName,
    )
    if (failure) {
      setError(failure.message)
      return { ok: false as const, needsEmailConfirmation: false }
    }
    if (data && 'needsEmailConfirmation' in data) {
      return { ok: true as const, needsEmailConfirmation: true }
    }
    setSession(data)
    return { ok: true as const, needsEmailConfirmation: false }
  }

  const logout = async () => {
    setError(null)
    const { error: failure } = await signOut()
    if (failure) setError(failure.message)
    setSession(null)
  }

  const switchWorkspace = async (workspaceId: string) => {
    await setActiveWorkspace(workspaceId)
    setSession((current) =>
      current ? { ...current, activeWorkspaceId: workspaceId } : current,
    )
  }

  return {
    session,
    isLoading,
    error,
    setError,
    login,
    register,
    logout,
    switchWorkspace,
    isAuthenticated: session !== null,
  }
}
