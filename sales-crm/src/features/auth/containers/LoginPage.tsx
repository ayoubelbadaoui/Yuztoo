import { useState } from 'react'
import type { FormEvent } from 'react'

import { controlClass, Field } from '@/components/ui/Field'

type Mode = 'login' | 'register'

type Props = {
  error: string | null
  onClearError: () => void
  onLogin: (email: string, password: string) => Promise<boolean>
  onRegister: (
    email: string,
    password: string,
    fullName: string,
  ) => Promise<{ ok: boolean; needsEmailConfirmation: boolean }>
}

export function LoginPage({
  error,
  onClearError,
  onLogin,
  onRegister,
}: Props) {
  const [mode, setMode] = useState<Mode>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fullName, setFullName] = useState('')
  const [isBusy, setIsBusy] = useState(false)
  const [info, setInfo] = useState<string | null>(null)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setIsBusy(true)
    setInfo(null)
    onClearError()

    if (mode === 'login') {
      await onLogin(email, password)
    } else {
      const result = await onRegister(email, password, fullName)
      if (result.ok && result.needsEmailConfirmation) {
        setInfo(
          'Compte créé. Confirmez votre e-mail puis reconnectez-vous.',
        )
        setMode('login')
      }
    }

    setIsBusy(false)
  }

  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-background px-4">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--accent)_0%,_transparent_55%)] opacity-80" />

      <div className="relative w-full max-w-md rounded-2xl border border-border bg-card p-8 shadow-sm">
        <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-muted-foreground">
          Yuztoo Sales
        </p>
        <h1 className="mt-2 text-2xl font-semibold tracking-tight text-card-foreground">
          {mode === 'login' ? 'Connexion' : 'Créer un compte'}
        </h1>
        <p className="mt-1 text-[13px] text-muted-foreground">
          CRM commercial — authentification Supabase, accès filtré par espace
          (RLS).
        </p>

        <form onSubmit={(event) => void submit(event)} className="mt-6 flex flex-col gap-3.5">
          {mode === 'register' && (
            <Field label="Nom" htmlFor="full-name">
              <input
                id="full-name"
                value={fullName}
                onChange={(event) => setFullName(event.target.value)}
                autoComplete="name"
                className={controlClass}
              />
            </Field>
          )}

          <Field label="E-mail" htmlFor="email">
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              autoComplete="email"
              className={controlClass}
            />
          </Field>

          <Field
            label="Mot de passe"
            htmlFor="password"
            hint="Au moins 6 caractères"
          >
            <input
              id="password"
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete={
                mode === 'login' ? 'current-password' : 'new-password'
              }
              className={controlClass}
            />
          </Field>

          {error && (
            <p className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-[12px] text-destructive">
              {error}
            </p>
          )}
          {info && (
            <p className="rounded-lg border border-border bg-muted/50 px-3 py-2 text-[12px] text-foreground">
              {info}
            </p>
          )}

          <button
            type="submit"
            disabled={isBusy}
            className="mt-1 flex h-10 items-center justify-center rounded-lg bg-primary px-4 text-[13px] font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
          >
            {isBusy
              ? 'Patientez…'
              : mode === 'login'
                ? 'Se connecter'
                : 'Créer mon espace'}
          </button>
        </form>

        <p className="mt-5 text-center text-[12px] text-muted-foreground">
          {mode === 'login' ? (
            <>
              Pas encore de compte ?{' '}
              <button
                type="button"
                className="font-medium text-foreground underline-offset-2 hover:underline"
                onClick={() => {
                  setMode('register')
                  onClearError()
                  setInfo(null)
                }}
              >
                S’inscrire
              </button>
            </>
          ) : (
            <>
              Déjà inscrit ?{' '}
              <button
                type="button"
                className="font-medium text-foreground underline-offset-2 hover:underline"
                onClick={() => {
                  setMode('login')
                  onClearError()
                  setInfo(null)
                }}
              >
                Se connecter
              </button>
            </>
          )}
        </p>
      </div>
    </div>
  )
}
