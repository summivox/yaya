module.exports = (grunt) ->
  'use strict'


  ############
  # plugins

  grunt.loadNpmTasks x for x in [
    'grunt-browserify'
    'grunt-contrib-clean'
    'grunt-iced-coffee'
    'grunt-contrib-uglify'
  ]


  ############
  # config

  config = ->
    @pkg = grunt.file.readJSON('package.json')

    # default
    @clean =
      build: ['build/*']
      dist: ['dist/*']
    @coffee =
      options:
        bare: true
    @uglify =
      options:
        preserveComments: 'some'
    @browserify = {}

    #
    @coffee.main =
      options:
        join: true
        sourceMap: true
        runtime: 'window'
      files: [
        {
          expand: true
          cwd: 'src/'
          src: '*.{iced,coffee}'
          dest: 'src/'
          ext: '.js'
        }
        'index.js': 'index.coffee'
      ]
    @browserify.main =
      options:
        browserifyOptions:
          standalone: 'yaya'
          transform: [
            'brfs'
            'coffeeify'
          ]
      files: [
        'dist/yaya.js': 'index.js'
      ]
    @uglify.main =
      files: [
        'dist/yaya.min.js': 'dist/yaya.js'
      ]
    grunt.registerTask 'main', [
      'browserify:main'
      # 'uglify:main'
    ]

    grunt.registerTask 'default', ['main']

    @

  grunt.initConfig new config