/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        notty: {
          bg: '#0f0f11',
          surface: '#16161a',
          card: '#1c1c22',
          accent: '#232355',
          indigo: '#4a45a0',
          'indigo-light': '#6b65c9',
          border: 'rgba(255, 255, 255, 0.08)',
          muted: 'rgba(255, 255, 255, 0.5)',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [],
}
