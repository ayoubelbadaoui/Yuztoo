import { Moon, Sun } from 'lucide-react'
import { useEffect, useState } from 'react'

import { ContractDocument } from '@/features/contracts/components/ContractDocument'
import { SignatureProof } from '@/features/contracts/components/SignatureProof'
import { SigningForm } from '@/features/contracts/components/SigningForm'
import type { Contract } from '@/features/contracts/domain/contract'
import { isSignable } from '@/features/contracts/domain/contract'
import { getContractBySigningToken } from '@/features/contracts/services/contractService'
import { useTheme } from '@/lib/useTheme'

function Shell({ children }: { children: React.ReactNode }) {
  const { theme, toggleTheme } = useTheme()

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-card">
        <div className="mx-auto flex max-w-2xl items-center justify-between gap-4 px-5 py-4">
          <div className="flex items-center gap-2.5">
            <span className="flex size-8 items-center justify-center rounded-lg bg-primary text-[15px] font-bold text-primary-foreground">
              Y
            </span>
            <div className="leading-tight">
              <p className="text-[15px] font-semibold text-card-foreground">
                yuztoo
              </p>
              <p className="text-[11px] italic text-muted-foreground">
                Le lien est la force.
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={toggleTheme}
            aria-label="Basculer le thème clair ou sombre"
            className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          >
            {theme === 'dark' ? (
              <Sun className="size-[18px]" strokeWidth={1.5} />
            ) : (
              <Moon className="size-[18px]" strokeWidth={1.5} />
            )}
          </button>
        </div>
      </header>

      <main className="mx-auto max-w-2xl px-5 py-8">{children}</main>
    </div>
  )
}

export function PublicContractPage({ token }: { token: string }) {
  const [contract, setContract] = useState<Contract | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    void getContractBySigningToken(token).then(({ data }) => {
      setContract(data)
      setIsLoading(false)
    })
  }, [token])

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background p-6">
        <div className="mx-auto h-96 max-w-2xl animate-pulse rounded-2xl bg-muted" />
      </div>
    )
  }

  if (!contract) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background p-6">
        <div className="max-w-sm text-center">
          <h1 className="text-lg font-semibold text-foreground">
            Ce contrat n’est plus disponible
          </h1>
          <p className="mt-1 text-[13px] text-muted-foreground">
            Le lien a peut-être expiré. Demandez-en un nouveau à votre
            conseiller Yuztoo.
          </p>
        </div>
      </div>
    )
  }

  const signable = isSignable(contract)

  return (
    <Shell>
      <div className="flex flex-col gap-6">
        <div className="rounded-2xl border border-border bg-card p-6">
          <ContractDocument contract={contract} />
        </div>

        {contract.signature ? (
          <SignatureProof signature={contract.signature} />
        ) : signable ? (
          <SigningForm token={token} onSigned={setContract} />
        ) : (
          <p className="rounded-xl border border-border bg-muted/40 px-4 py-3 text-[13px] text-muted-foreground">
            Ce contrat n’est pas ouvert à la signature pour le moment. Votre
            conseiller Yuztoo peut vous envoyer un nouveau lien.
          </p>
        )}

        <p className="text-center text-[11px] text-muted-foreground">
          Document de démonstration, sans valeur juridique.
        </p>
      </div>
    </Shell>
  )
}
