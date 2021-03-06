# Copyright (c) 2009 Hallison Batista
class Postview::Settings

  # Default keys that 
  DEFAULT_SITE_KEYS = [ :title, :subtitle, :author, :email, :domain, :directory, :theme, :token ]
  DEFAULT_DIRECTORIES_KEYS = [ :posts, :archive, :drafts, :themes ]
  DEFAULT_SECTIONS_KEYS = [ :root, :posts, :archive, :drafts, :tags, :search, :about, :dashboard ]
  # Default values that will be used for valid attributes in settings file.
  DEFAULTS = {
    :site => {
      :title     => "Postview",
      :subtitle  => "Post your articles",
      :author    => "Postview",
      :email     => "postview@example.com",
      :domain    => "example.com",
      :directory => "/var/www/example",
      :theme     => "default",
      :token     => "e44257415827b00557ae5505f93e112d6158c4ba3c567aefbbff47288c6bf7cd" # Password: admin
    },
    :directories => {
      :posts   => "posts",
      :archive => "posts/archive",
      :drafts  => "posts/drafts",
      :themes  => "themes"
    },
    :sections => {
      :root      => "/",
      :posts     => "/posts",
      :tags      => "/tags",
      :archive   => "/archive",
      :drafts    => "/drafts",
      :search    => "/search",
      :about     => "/about",
      :dashboard => "/dashboard"
    }
  }
  FILE_NAME = "settings.yml"
  FILE_DIR  = "config"

  # Site attributes
  attr_reader :site

  # Directories that be used for load files.
  attr_reader :directories

  # Section names that be used in mapping routes into application.
  attr_reader :sections

  # Initialize the settings using attributes passed by arguments.
  # Only attributes valid are read. See DEFAULTS.
  def initialize(attributes = {})
    attributes.symbolize_keys.merge(DEFAULTS) do |key, value, default|
      if value
        value.merge(default) do |attribute, content, not_empty|
          content || not_empty
        end
      else
        default
      end
    end.instance_variables_set_to(self)
  end

  # Build site using attributes found in +site+ key.
  def build_site
    build_all_finders_for(Postview::Site.new(site))
  end

  # Build a simple structure for pages.
  def build_page
    OpenStruct.new(:title => "", :keywords => [])
  end

  # Build finders for site. The finders load all post files
  # placed in directories setted in +directories+ values.
  def build_all_finders_for(site)
    site.find = build_finder_for(:posts)
    site.find_in_archive = build_finder_for(:archive)
    site.find_in_drafts = build_finder_for(:drafts)
    site
  end

  # Build a specific finder for directory.
  def build_finder_for(directory)
    Postage::Finder.new(path_to(directory))
  end

  # Load a default settings values from file placed in +config/settings.yml+.
  def self.load
    load_file(file)
  end

  # Load a specific settings file.
  # Returns default values for attributes not found.
  def self.load_file(file_name)
    begin
      new(YAML.load_file(file_name) || DEFAULTS)
    rescue Errno::ENOENT
      new(DEFAULTS)
    end
  end

  # Load file from a path.
  def self.load_file_from(path)
    file = Pathname.new(path).join(FILE_DIR, FILE_NAME)
    new(YAML.load_file(file))
  end

  # Build settings file using DEFAULTS.
  def self.build_default_file
    file.open "w+" do |file|
      file << DEFAULTS.to_yaml
    end unless file.exist?
  end

  # Returns settings file.
  def self.file
    Postview.config.path.join(FILE_DIR, FILE_NAME)
  end

  # Check directory and returns file that matches with a pattern.
  def file_names_from(directory, pattern = "**.*")
    path_to(directory, pattern)
  end

  # Returns a valid directory loaded from settings file.
  def path_to(name, *paths)
    return Pathname.new(directories[name], *paths) if directories[name].match(%r{^/.*})
    Postview.config.path.join(directories[name], *paths)
  end

  # Parse all attributes to hash.
  def to_hash
    DEFAULTS.keys.inject({}) do |hash, method|
      hash[method] = send(method)
      hash
    end
  end

end # class Postview::Settings

