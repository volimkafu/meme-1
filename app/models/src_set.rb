# encoding: UTF-8

class SrcSet < ActiveRecord::Base
  validates :name, presence: true
  validate :name, :one_active_name

  has_and_belongs_to_many :src_images
  belongs_to :user

  def one_active_name
    if new_record? && SrcSet.active.exists?(name: name) ||
        !is_deleted && SrcSet.where('name = ? AND id != ?', name, id).active.count > 0
      errors.add :name, 'has already been taken'
    end
  end

  def add_src_images(add_id_hashes)
    to_add = SrcImage.find_all_by_id_hash(add_id_hashes) - self.src_images

    unless to_add.empty?
      self.src_images.concat(to_add)
      self.touch
    end
  end

  def delete_src_images(delete_id_hashes)
    to_delete = SrcImage.find_all_by_id_hash(delete_id_hashes)

    unless to_delete.empty?
      self.src_images.delete(*to_delete)
      self.touch
    end
  end

  def thumbnail
    recent = src_images.without_image.active.most_used
    recent.first.src_thumb unless recent.empty?
  end

  def thumb_width
    thumb = thumbnail
    thumb.width if thumb
  end

  def thumb_height
    thumb = thumbnail
    thumb.height if thumb
  end

  scope :active, -> { where is_deleted: false }

  scope :owned_by, ->(user) { where user_id: user.id }

  scope :most_recent, ->(limit=1) { order(:quality, :'src_sets.updated_at').reverse_order.limit(limit) }

  scope :front_page, -> { where('quality >= ?', MemeCaptainWeb::Config::SetFrontPageMinQuality) }

  scope :not_empty, -> { joins(:src_images).where('src_images.is_deleted' => false).group(:'src_sets.id') }
end
