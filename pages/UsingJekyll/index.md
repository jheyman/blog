---
layout: page
title: Using Jekyll to build this site
tagline: Notes on using Jekyll framework
tags: jekyll, web, ruby, liquid, markdown
---
{% include JB/setup %}

While looking for a VERY simple way to create and store web pages keeping notes on my projects, I checked the Github Pages option and its associate static site generation framework: [Jekyll](http://jekyllrb.com). It looked like the perfect fit, for a person like me with web skills close to zero.

Below are a few notes (to myself) to setup the site building process:

### Installing jekyll

	sudo apt-get install ruby1.9.1 ruby1.9.1-dev make nodejs rake
	sudo gem install jekyll
	jekyll new [site name]
	cd [site name] 
	jekyll serve
	
The generated site is then accessible locally via http://localhost:4000
In practice, I used [Jekyll Bootstrap](http://jekyllbootstrap.com/) boilerplate to get started.

### Setting-up the hosting on github
Create a repo on github (e.g. blog.git)

	mkdir blog
	cd blog
	git init
	git add . --all
	git commit -m "initial commit"
	git remote add origin https://github.com/[your githubname]/[repo name].git
	git push -u origin master 
	git branch gh-pages
	git checkout gh-pages

### Customizing \_config.yml
Update `base_url` to http://\[your github name\].github.io/\[repo name\]
This is only required because I will no use Github Page's built-in jekyll generator, and I require full URLs when generating the site locally.

### Previewing the site locally
To generate the static pages and preview them locally

	jekyll serve --baseurl=

The site can then be accessed at `localhost://4000`

### Updating the site content
Github pages hosting offers dynamic jekyll files rendering automatically. However, it does not allow custom plugins. Since I do use some plugins (see below), I chose instead to only push to github the <i>result</i> of the pages generation, not the source markdown/liquid files. To update the site, I just create/edit pages as appropriate, then:

	jekyll build
	cd publish/blog/
	rsync -arv ../../_site/ .
	git add . --all
	git commit -m "update for XYZ"
	git push -u origin gh-pages

The resulting site is then accessble from http://\[your github name\].github.io/\[repo name\]/

### Generating a tag/keyword index page
Jekyll supports "tags" in post articles by default, and is able to generate an index of pages from this tag list very easily.
One just needs to add a `tags: ` line in the YAML front matter of the markdown files.
Unfortunately, when these tags are inserted in <i>pages</i> (i.e. not blog posts), things are not so simple anymore. I finally found an option relying on a custom jekyll plugin, largely based on this great blog entry:

[http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/](http://brizzled.clapper.org/blog/2010/12/20/some-jekyll-hacks/)

I just modified a few of the plugin files to achieve my purpose:

#### site.rb

In this file, posts tags AND pages tags are concatenated into a single list
		
	module Jekyll
	  class Site

	    def pages_by_tag
	      tag_ref = {}
	      temp = self.posts.dup
	      temp.concat(self.pages)
	      temp.each do |page|  
	        page.tags.each do |tag|
	          pages = tag_ref.fetch(tag, Array.new)
	          pages << page
	          tag_ref[tag] = pages
	        end
	      end
	      tag_ref
	    end
	  end
	end

#### page.rb	

This hack just lets jekyll understand that for BOTH pages and posts, tags are to be read from a comma-separated list and converted to our custom `Jekyll::Tag` objects

	module Jekyll
		class Page
		    def tags
		        (self.data['tags'] || '').split(',').map {|t| Tag.new(t)}
		    end
		end
		
		class Post
		    def tags
		        (self.data['tags'] || '').split(',').map {|t| Tag.new(t)}
		    end
		end
	end

#### tags.rb

The actual work of generating the tag index HTML page is done here. 

	module Jekyll
	  class MyTagIndex < Page
	    def initialize(site, base, dir, tags)    
	      @site = site
	      @base = base
	      @dir = dir
	      @name = 'tags.html'
	      self.process(@name)
	      tag_index = (site.config['tag_index_layout'] || 'tag_index') + '.html'
	      self.read_yaml(File.join(base, '_layouts'), tag_index)
	      self.data['pages_by_tags'] = tags
	      self.data['title'] = "Tag index"
	    end
	  end  	  
	  class TagGenerator < Generator
	    safe true
	    def generate(site)
	      if site.layouts.key? 'tag_index'
	        dir = "."
	        tags = Hash[site.pages_by_tag.sort]
	        generate_tag_index(site, dir, tags)           
	      end
	    end
	    def generate_tag_index(site, dir, tags)
	      index = MyTagIndex.new(site, site.source, dir, tags)
	      index.render(site.layouts, site.site_payload)
	      index.write(site.dest)
	      site.pages << index
	    end
	  end
	end

### Getting google analytics to work
Jekyll bootstrap includes support for Google Analytics by default, by just adjusting config parameters in the `_config.yml` file (in the `analytics` section, set the `provider` param to "google" and the `tracking_id` to your custom id).

In my specific context, there is one catch however: since Jekyll Bootstrap is aimed at github-based jekyll rendering, it only activates some of its features if the site generation is done in "safe" mode (i.e. no plugins allowed). This is the case for the github-based rendering, but is not what I want since I render the site locally to be able to use plugins. So, to still benefit from jekyll boostrap support for google analytics, I hacked the `_include/JB/analytics` file and removed the `if site.safe` condition on the first line.
 
### Updating the theme

Custom themes should be placed inside `_theme_packages` folder, then installed via:

	rake theme:install name="THEME-NAME"

### Editing a custom theme

A cool multi-platform tool to compile LESS stylesheets I have been using is [**Koala**](http://koala-app.com/)

### Using jekyll on Windows10

I followed the instructions for installing Ubuntu's **bash** on Windows10, described [here](https://jekyllrb.com/docs/windows/), and got it to work well enough. As indicated, auto-regeneration does not work (i.e. watch option). I use this command line when working from bash on Windows:

	jekyll serve --baseurl= --no-watch

 