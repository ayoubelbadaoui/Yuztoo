import { ScanLine, Store } from 'lucide-react'
import NfcIcon from '../../components/NfcIcon.jsx'
import StepsWithMedia from '../../components/StepsWithMedia.jsx'
import { PRO_SETUP } from '../commercantsContent.js'

const ICONS = { store: Store, nfc: NfcIcon, scan: ScanLine }

export default function ProSetup() {
  return <StepsWithMedia data={PRO_SETUP} icons={ICONS} id="mise-en-place" />
}
