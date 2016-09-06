require 'test_helper'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: 'file:memdb1?mode=memory&cache=shared'
)
ActiveRecord::Schema.verbose = false

def setup_db
  # AR caches columns options like defaults etc. Clear them!
  ActiveRecord::Base.connection.create_table :schools do |t|
    t.column :name, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end

  ActiveRecord::Base.connection.create_table :teachers do |t|
    t.column :name, :string
    t.column :school_id, :integer
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end

  ActiveRecord::Base.connection.create_table :courses do |t|
    t.column :name, :string
    t.column :school_id, :integer
    t.column :teacher_id, :integer
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end

  ActiveRecord::Base.connection.schema_cache.clear!
  [School, Teacher, Course].each do |klass|
    klass.reset_column_information
  end
end

def teardown_db
  if ActiveRecord::VERSION::MAJOR >= 5
    tables = ActiveRecord::Base.connection.data_sources
  else
    tables = ActiveRecord::Base.connection.tables
  end

  tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class School < ActiveRecord::Base
  has_many :teachers
  has_many :courses
end

class Teacher < ActiveRecord::Base
  belongs_to :school
  has_many :courses
end

class Course < ActiveRecord::Base
  belongs_to :school
  belongs_to :teacher
  set_from :teacher, targets: [:school_id], update_for_change: true
end

class SetFromTestCase < Minitest::Test
  def teardown
    teardown_db
  end

  def setup
    setup_db
  end

  def test_set_from_when_initialize
    school = School.create
    teacher = Teacher.create(school: school)
    course = teacher.courses.build
    assert_equal school.id, course.school_id
  end

  def test_set_from_when_save
    school = School.create
    teacher = Teacher.create(school: school)
    course = Course.new
    course.teacher = teacher
    course.save
    assert_equal school.id, course.school_id
  end

  def test_set_from_when_change
    school1 = School.create
    teacher1 = Teacher.create(school: school1)
    school2 = School.create
    teacher2 = Teacher.create(school: school2)
    course = teacher1.courses.create
    assert_equal school1.id, course.school_id
    course.update(teacher: teacher2)
    assert_equal school2.id, course.school_id
  end

end