## set_from

### Example
```
class School < ActiveRecord::Base
  has_many :teachers
  has_many :courses
end

class Teacher < ActiveRecord::Base
  belongs_to :school
  has_many :courses
end

class Course < ActiveRecord::Base
  belongs_to :teacher
  belongs_to :school
  set_from :teacher, targets: [:school_id], update_for_change: true
end

school = School.create
teacher = Teacher.create(school: school)
course = teacher.courses.create
course.school_id # => school.id
```