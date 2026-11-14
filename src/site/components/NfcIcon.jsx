/**
 * NFC mark from Tabler Icons (MIT, https://tabler.io/icons/icon/nfc).
 * Same 24px stroke grid as lucide, so it sits beside the other icons.
 */
export default function NfcIcon({ size = 24, strokeWidth = 2, ...rest }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      {...rest}
    >
      <path d="M11 20a3 3 0 0 1 -3 -3v-11l5 5" />
      <path d="M13 4a3 3 0 0 1 3 3v11l-5 -5" />
      <path d="M4 7a3 3 0 0 1 3 -3h10a3 3 0 0 1 3 3v10a3 3 0 0 1 -3 3h-10a3 3 0 0 1 -3 -3l0 -10" />
    </svg>
  )
}
