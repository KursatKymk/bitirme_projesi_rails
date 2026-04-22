// const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          midnight: '#00033D',
          navy: '#0600AB',
          azure: '#0033FF',
          sky: '#977DFF',
          ice: '#F2E6EE'
        }
      },
      fontFamily: {
//         sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: []
}
