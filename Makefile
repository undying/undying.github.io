
post_new:
	bundle exec tools/post_new.rb

jekyll_doctor:
	bundle exec jekyll doctor

jekyll_build: jekyll_doctor
	bundle exec jekyll build

jekyll_server: jekyll_doctor jekyll_build
	reset
	bundle exec jekyll server --livereload

publish: jekyll_build
	cd _site/ && git add . && git commit -av
