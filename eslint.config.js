import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'

/**
 * Enforces the DDD Holy Book: Firebase only in src/data, and file size limits.
 * The restricted-import allowlist stays empty forever (DDD book §9).
 */
export default [
  { ignores: ['dist/**', 'dist-ssr/**', 'node_modules/**'] },

  {
    files: ['**/*.{js,jsx}'],
    ...js.configs.recommended,
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: 'module',
      globals: { ...globals.browser, ...globals.node },
      parserOptions: { ecmaFeatures: { jsx: true } },
    },
    plugins: { 'react-hooks': reactHooks },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'max-lines': ['error', { max: 500, skipBlankLines: true, skipComments: true }],
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['firebase/*', '**/lib/firebase'],
              message:
                'Firebase may only be imported inside src/data. See docs/holy-books/DDD_HOLY_BOOK.md §1.',
            },
            {
              group: ['**/lib/feature/**', '**/*.dart'],
              message:
                'This branch is website-only: never import Flutter app or CRM code.',
            },
          ],
        },
      ],
    },
  },

  {
    files: ['src/data/**', 'src/lib/**', 'src/**/*Content.js', 'src/seo/**'],
    rules: {
      'max-lines': ['error', { max: 800, skipBlankLines: true, skipComments: true }],
      'no-restricted-imports': 'off',
    },
  },

  {
    files: ['src/**/*Page.jsx'],
    rules: {
      'max-lines': ['error', { max: 550, skipBlankLines: true, skipComments: true }],
    },
  },

  {
    files: ['src/site/components/**', 'src/site/sections/**'],
    rules: {
      'max-lines': ['error', { max: 450, skipBlankLines: true, skipComments: true }],
    },
  },
]
