# coding: utf-8

## Copyright (c) 2015 Hasegawa.Tadamitsu
## This software is released under the MIT License.
## http://opensource.org/licenses/mit-license.php

require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require 'singleton'
require 'logger'
require 'pry'
require 'fileutils'
require 'digest/md5'
require 'json'


class Exception
  def backtrace_to_html
    trace = self.backtrace
    sanitized_trace = trace.map do |val| 
      val.gsub /[<|>]/, ""
    end

    ret = sanitized_trace.join "<br>\n"
    return ret
  end
end

class MyLogger
  include Singleton
  attr_reader :logger

  def initialize
    STDOUT.sync = true
    STDERR.sync = true
    @logger = Logger.new STDOUT
  end

end

class FileMgr
  BUFFER_PATH="/var/tmp/mp3_data"
  def self.init_x
    MyLogger.instance.logger.info "delete #{BUFFER_PATH}"
    FileUtils.rm_rf   BUFFER_PATH
    FileUtils.mkdir_p BUFFER_PATH
  end

  def self.music_cut org_mp3_file, out_file_path,out_file_name
   output_base_path = File.join BUFFER_PATH, out_file_path
   FileUtils.mkdir_p output_base_path
   output = File.join output_base_path,out_file_name
   cmd = "sox #{org_mp3_file} #{output} trim 0 20 fade h 1 0 10"
   system cmd
   ret = $?
   if ret  != 0
     info="bad status sox.#{ret}/#{cmd}."
     MyLogger.instance.logger.info info
     raise "#{info}"
   end
  end

  def self.pack       out_file_path, output_name, datas
   output_base_path = File.join BUFFER_PATH, out_file_path
   output = File.join output_base_path, output_name
   FileUtils.rm_rf  output
   cmd="zip -j #{output} "
   datas.each do |fi|
    aa = File.join BUFFER_PATH, out_file_path
    ab = File.join aa,fi
    cmd += "#{ab} "
   end
   system cmd
   return output
  end

end


helpers do
  # nothing

end

configure do
  Rack::URLMap.new("/sub" => Sinatra::Application)
  set :environment, :production
  set :show_exceptions, false 
  set :public_folder, File.dirname(__FILE__) + '/public'
  mime_type :zip, 'application/zip'
  enable :sessions
  set :sessions,  secret: 'xxx'
  MyLogger.instance.logger.info 'logger start'
  FileMgr.init_x
end


get '/' do
  MyLogger.instance.logger.info "access /"
  haml :index_page
end

post '/upload' do
  MyLogger.instance.logger.info "access /upload"
  temp_file =params[:file]["0"][:tempfile].path
  base_path = session[:session_id].to_s
  file_name = Time.now.instance_eval { '%s%03d' % [strftime('%Y%m%d_%H%M%S_'),
                    (usec / 1000.0).round] } + ".mp3"
  status = FileMgr.music_cut temp_file, base_path, file_name
  ret=Hash.new
  ret[:key]  = Time.now.strftime("%Y%m%d%H%M%S")
  ret[:name] = file_name
  return ret.to_json
end

post '/execute' do
  MyLogger.instance.logger.info "access execute"
  datas=Array.new
  params.each do |key, value|
    unless /\A[0-9]{8}_[0-9]{6}_[0-9]{3}\.mp3\z/ =~ value
      MyLogger.instance.logger.info "bad filename #{key},#{value}"
      next
    end
    datas.push value
  end

  if datas.size == 0
    @msg = "出力されるCDイメージに一つもファイルがありません。" +
           "ファイルをドロップしてください"
    return haml :index_page
  end
  
  base_path = session[:session_id].to_s
  output_file ="cd_image.zip"

  ret = FileMgr.pack base_path, output_file, datas
  send_file  ret, :filename=> output_file
end

error do |e|
  status 500
  @exception = e
  haml :error_page
end

not_found do
  "Whoops! You requested a route that wasn't available."
end

__END__
@@ layout
!!! 5
%html
  %header
    %script{ :src=>"./js-lib/jquery.js" }
    %script{ :src=>"./js-lib/dropzone.js" }

  :css
    div#upload_form {
      border: 1px solid black;
      width: 300px;
      height: 300px;
      padding: 10px;
    }
    div#image_drop_area{
      background-color:#ffffe0;
      width:300px;
      height:200px;
    }
    div#preview_area{
      background-color:#e6e6e6;
      min-height:200px;
      width:600px;
    }

  %body
    %div.title
      %h1 music cutter
    %div.body
      = yield
    %div.footer
      %hr 
      create time at
      = Time.now
      %br
      %a{ :href=>"/"} index pageに戻る

@@ error_page
%div.msg
  %strong
    = @exception.message

%div.main_body
  %a{ :href=>"/"} index pageに戻る
  %br
  %hr
  %h2 トレース情報  @exception.backtrace_to_html


@@ index_page
%div.msg
  %strong
    = @msg
:javascript
  $(function(){
  $('#image_drop_area').dropzone({
        url:'./upload',
        paramName:'file',
        maxFilesize:50, //MB
        parallelUploads:1,
        uploadMultiple:true,
        addRemoveLinks:true,
        previewsContainer:'#preview_area',
        createImageThumbnails:false,
        acceptedFiles:".mp3",
        uploadprogress:function(_file, _progress, _size){
           _file.previewElement.querySelector("[data-dz-uploadprogress]").
              style.width = "" + _progress + "%";
           $(_file.previewElement.querySelector("[data-dz-uploadprogress]"))
             .text(_progress  + "%");
        },
        success:function(_file, _return, _xml){
           console.log(_xml );
           console.log(_return );
           data = JSON.parse( _return );
           _file.previewElement.classList.add("dz-success");
           var element = document.createElement('input');
           element.type = "hidden" ;
           element.name = "file" + data.key  ;
           element.value = data.name ;
           _file.previewElement.appendChild(element)
        },
        error:function(_file, _error_msg){
          var ref;
          (ref = _file.previewElement) != null ?
              ref.parentNode.removeChild(_file.previewElement) : void 0;
        },
        removedfile:function(_file){
           var ref;
           (ref = _file.previewElement) != null ?
              ref.parentNode.removeChild(_file.previewElement) : void 0;
        },
        previewTemplate: "<div class=\"dz-preview dz-file-preview\">\n  <div class=\"dz-details\">\n    <div class=\"dz-filename\"><span data-dz-name></span></div>\n    <div class=\"dz-size\" data-dz-size></div>\n   </div>\n  <div class=\"dz-progress\"><span class=\"dz-upload\" data-dz-uploadprogress>0%</span></div>\n  <div class=\"dz-success-mark\"><span>&#10004;</span></div>\n  <div class=\"dz-error-mark\"><span>&#10008;</span></div>\n  <div class=\"dz-error-message\"><span data-dz-errormessage></span></div>\n</div>",
        dictRemoveFile:'削除',
        dictCancelUpload:'キャンセル'
     });
  });

%div.main_body#top
  %div#image_drop_area
    ここにmp3ファイルをドロップしてください。
  %br
  %br
  %form{ :action=>'/execute',:method=>"post"}
    %div#preview_area
      出力されるCDのイメージ
    %input{ :type=>"submit" }
