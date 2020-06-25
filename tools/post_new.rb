#! /usr/bin/env ruby

require 'time'

project_dir = File.expand_path(__dir__)
project_dir.slice!(/\/[^\/]+$/)

date = Time.now()

printf("Enter title: ")
title = $stdin.gets().strip()
title_clean = title.gsub(/[:\s]/, '-').downcase()

printf("Enter tags: ")
tags = $stdin.gets().strip()

post_file = "#{date.strftime('%Y-%m-%d')}-#{title_clean}.markdown"
if File.file?(post_file)
  puts("file #{post_file} already exists")
  exit(123)
end

template = <<-EOF
---
layout: post
title: "#{title}"
date: #{date}
tags: #{tags}
---

EOF

File.open(File.join(project_dir, '_posts', post_file), 'w') do |f|
  f.write(template)
end

