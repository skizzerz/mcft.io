const gulp = require('gulp');
const less = require('gulp-less');
const path = require('path');

gulp.task('less', function () {
    return gulp.src('./public/stylesheets/*.less')
        .pipe(less({
            paths: [path.join(__dirname, 'less', 'includes')]
        }))
        .pipe(gulp.dest('./public/stylesheets'));
});

gulp.task('watch', function () {
    gulp.watch('./public/stylesheets/*.less', gulp.series('less'));
});

gulp.task('default', gulp.series('less', 'watch'));
