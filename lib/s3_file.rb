module S3File

  # Legacy submission files were handled by S3 direct upload and we stored their
  # Amazon key in the "filepath" field. Here we check if it has a value, and if
  # so we use this to retrieve our secure url. If not, we use the path supplied by
  # the carrierwave uploader

  attr_accessor :process_file_upload

  include S3Manager::Basics

  # @mz todo: add specs
  def url
    if Rails.env.development?
      file.url 
    else
      bucket.object(s3_object_file_key).presigned_url(:get, expires_in: 900).to_s #15 minutes
    end
  end

  # @mz todo: add specs
  def s3_object_file_key
    filepath.present? ? CGI::unescape(filepath) : file.path
  end

  def remove
    bucket.object(s3_object_file_key).delete
  end

  private

  def strip_path
    if filepath.present?
      filepath.slice! "/#{bucket_name}/"
      write_attribute(:filepath, filepath)
      name = filepath.clone

      # 2015-01-06-11-16-33%2Fsome-file.jpg -> some-file.jpg
      # see s3 file structure created in /app/helpers/uploads_helper.rb
      name.slice!(/.*\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}%2F/)
      write_attribute(:filename, name)
    end
  end
end
