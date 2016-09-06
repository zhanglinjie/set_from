require "set_from/version"
module SetFrom
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Example
  # class School < ActiveRecord::Base
  #   has_many :teachers
  #   has_many :courses
  # end

  # class Teacher < ActiveRecord::Base
  #   belongs_to :school
  #   has_many :courses
  # end

  # class Course < ActiveRecord::Base
  #   belongs_to :teacher
  #   belongs_to :school
  #   set_from :teacher, targets: [:school_id], update_for_change: true
  # end

  # school = School.create
  # teacher = Teacher.create(school: school)
  # course = teacher.courses.create
  # course.school_id # => school.id

  module ClassMethods
    def set_from(source, options={})
      targets = options.fetch(:targets, [])
      if targets.last.is_a?(Hash)
        hash_params = targets.pop
        targets_hash = Hash[targets.map{|key| [key, key]}]
        targets_hash = targets_hash.merge(hash_params)
      else
        targets_hash = Hash[targets.map{|key| [key, key]}]
      end
      update_for_change = options.fetch(:update_for_change, false)
      prefix = options.fetch(:prefix, false)
      self.class_eval do
        after_initialize "set_from_#{source}".to_sym, if: :new_record?
        before_validation "set_from_#{source}".to_sym, if: :new_record?
        if update_for_change
          before_save "set_from_#{source}_when_change".to_sym, if: ->{ persisted? && send("#{source.to_s.foreign_key}_changed?")}
        end
        define_method "set_from_#{source}".to_sym do
          from_source = self.send(source)
          targets_hash.each do |source_target_method, set_target_method|
            set_target_method = prefix ? "#{source}_#{set_target_method}" : set_target_method
            if self.respond_to?(set_target_method) && self.send(set_target_method).blank? && from_source.present? && from_source.respond_to?(source_target_method)
              self.send("#{set_target_method}=", from_source.send(source_target_method))
            end
          end
        end
        define_method "set_from_#{source}_when_change".to_sym do
          from_source = self.send(source)
          targets_hash.each do |source_target_method, set_target_method|
            set_target_method = prefix ? "#{source}_#{set_target_method}" : set_target_method
            if self.respond_to?(set_target_method) && from_source.present? && from_source.respond_to?(source_target_method)
              self.send("#{set_target_method}=", from_source.send(source_target_method))
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, SetFrom) if defined?(ActiveRecord)