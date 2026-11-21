type Props = {
  title: string
  description: string
}

/** Temporary content frame: the shell is the deliverable, features come next. */
export function PlaceholderPage({ title, description }: Props) {
  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          {title}
        </h1>
        <p className="text-[13px] text-muted-foreground">{description}</p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {[0, 1, 2].map((index) => (
          <div
            key={index}
            className="h-28 rounded-xl border border-border bg-card"
          />
        ))}
      </div>

      <div className="rounded-xl border border-border bg-card p-6">
        <div className="mb-6 h-5 w-1/3 rounded-md bg-muted" />
        <div className="mb-6 h-px bg-border" />
        <div className="flex flex-col gap-3">
          {[0, 1, 2, 3, 4].map((index) => (
            <div key={index} className="h-11 rounded-lg bg-muted" />
          ))}
        </div>
      </div>
    </div>
  )
}
