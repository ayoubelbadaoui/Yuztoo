import { supabase } from '@/lib/supabaseClient'

type Result<T> = { data: T | null; error: Error | null }

export type UploadedMedia = {
  id: string
  publicUrl: string
  mimeType: string
  originalName: string
  byteSize: number
}

const ALLOWED = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'video/mp4',
  'video/quicktime',
])

/** Upload to public marketing-media bucket then register the row. */
export async function uploadMarketingMedia(input: {
  workspaceId: string
  file: File
}): Promise<Result<UploadedMedia>> {
  try {
    if (!ALLOWED.has(input.file.type)) {
      throw new Error('Format non supporté (JPEG, PNG, WebP ou MP4)')
    }
    if (input.file.size > 50 * 1024 * 1024) {
      throw new Error('Fichier trop volumineux (max 50 Mo)')
    }

    const ext = input.file.name.split('.').pop()?.toLowerCase() || 'bin'
    const path = `${input.workspaceId}/${crypto.randomUUID()}.${ext}`

    const { error: uploadError } = await supabase.storage
      .from('marketing-media')
      .upload(path, input.file, {
        cacheControl: '3600',
        upsert: false,
        contentType: input.file.type,
      })
    if (uploadError) throw new Error(uploadError.message)

    const { data: publicData } = supabase.storage
      .from('marketing-media')
      .getPublicUrl(path)

    const { data: row, error: rowError } = await supabase
      .from('marketing_media')
      .insert({
        workspace_id: input.workspaceId,
        storage_path: path,
        public_url: publicData.publicUrl,
        mime_type: input.file.type,
        byte_size: input.file.size,
        original_name: input.file.name,
      })
      .select('id, public_url, mime_type, original_name, byte_size')
      .single()

    if (rowError || !row) throw new Error(rowError?.message ?? 'Enregistrement média échoué')

    return {
      data: {
        id: row.id,
        publicUrl: row.public_url,
        mimeType: row.mime_type,
        originalName: row.original_name,
        byteSize: row.byte_size,
      },
      error: null,
    }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
