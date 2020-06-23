
post_new:
	bundle exec tools/post_new.rb

jekyll_doctor:
	bundle exec jekyll doctor

jekyll_build:
	bundle exec jekyll build

jekyll_server: jekyll_doctor
	reset
	bundle exec jekyll server --livereload
