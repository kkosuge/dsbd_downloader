#coding: utf-8
require 'pp'
require 'open-uri'
require 'rexml/document'


mail = ""
pass = ""
@path = "" #落としてきたやつ保存するフォルダの絶対パス



#読み込み済みのやつを読む
begin
 loaded = open(@path+"loaded.txt")
 till = loaded.read
rescue
  till = nil
end


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
      #TODO 正規表現やめたい
      link_url = doc.to_s.scan(/<photo-link-url>.*?<\/photo-link-url>/)
      dl_url = doc.to_s.scan(/<photo-url max-width='1280'>.*?<\/photo-url>/)
      dl_url.each_with_index do |d,i|
        unless link_url[i]
          l = d.gsub(/<photo-url max-width='1280'>|<\/photo-url>/, "")
        else
          l = link_url[i].gsub(/<photo-link-url>|<\/photo-link-url>/, "")
        end
        d = d.gsub(/<photo-url max-width='1280'>|<\/photo-url>/, "")
        break if @till == d
        photo << {:link_url => l, :dl_url => d}
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
    name = img[:link_url].gsub(/http:\/\//,'')
    name = name.gsub('/',':')

    open(@path+name,'w') do |file|
      open(img[:dl_url]) do |image|
        file.write(image.read)
      end
    end
  end
end



t = TumblrDownloader.new(mail, pass)
t.till = till if till
photo = t.photo

save_photo(photo)

#最後に保存したやつ保存する
File.open(@path+"loaded.txt","w"){|f| f.print photo[0][:dl_url] if photo[0]}
