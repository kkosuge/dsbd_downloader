#coding: utf-8
require 'open-uri'
require 'rexml/document'

require 'rubygems'
require 'pit'

config = Pit.get("tumblr", :require => {
                   "mail" => "your email in tumblr",
                   "pass" => "your password in tumblr"
                 })
mail = config['mail']
pass = config['pass']

@path = ARGV[0] or abort "usage: $0 <path_to_savedir>"

#check directory
while( /\/$/ =~ @path )
  @path = @path.chop
end
File.directory? @path or abort "no such directory #{@path}"


class TumblrDownloader
  attr_accessor :num, :till

  def initialize(mail,pass)
    @mail = mail
    @pass = pass
    @num = 50
    @till = 'last'
  end

  def url
    comp = "?email=#{@mail}&password=#{@pass}&type=#{@type}&num=#{@num.to_s}"
    dsbd = "http://www.tumblr.com/api/dashboard"
    url = dsbd + comp
  end

  def photo
    @type = 'photo'
    photo = []
    open(self.url) do |f|
      doc = REXML::Document.new(f)
      post = doc.root.get_elements("//post")

      post.each do |el|
        dl_url_el   = el.get_elements("photo-url[@max-width = '1280']")[0]
        link_url_el = el.get_elements("photo-link-url")[0]

        timestamp   = el.attributes.get_attribute("unix-timestamp").to_s
        dl_url   = dl_url_el.get_text.to_s
        link_url = link_url_el ? link_url_el.get_text.to_s : nil

        break if @till == dl_url
        photo << {:link_url => link_url, :dl_url => dl_url, :timestamp => timestamp}
      end
    end
    return photo
  end

  def text
  end

  def quote
  end

  def video
  end

end


def save_photo(photo)
  photo.each do |img|
    url_for_filename = img[:link_url] ? img[:link_url] : img[:dl_url]
    basename = url_for_filename.gsub(/http:\/\//,'')
    basename = basename.gsub('/','_')

    open(img[:dl_url]) do |image|
      filename = img[:timestamp] + basename + get_extension(image)
      open(@path + "/" + filename,'w') do |file|
        file.write(image.read)
      end
    end
  end
end

def get_extension(file)
  header = file.read(8)
  file.pos = 0
  if ( /^\x89PNG/n.match(header) ) 
    return ".png"
  elsif (/^GIF8[79]a/n.match(header) )
    return ".gif"
  elsif( /^\xff\xd8/n.match(header) )
    return ".jpg"
  elsif( /^BM/n.match(header) )
    return ".bmp"
  else
    return ""
  end
end

#読み込み済みのやつを読む
begin
  loaded = open(@path+"/loaded.txt")
  till = loaded.read
rescue
  till = nil
end


t = TumblrDownloader.new(mail, pass)
t.till = till if till
photo = t.photo

save_photo(photo)

#最後に保存したやつ保存する
File.open(@path+"/loaded.txt","w"){|f| f.print photo[0][:dl_url] if photo[0]}
