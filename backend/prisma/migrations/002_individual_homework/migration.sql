ALTER TABLE homework ADD COLUMN IF NOT EXISTS student_id uuid REFERENCES students(id);
CREATE INDEX IF NOT EXISTS homework_student_idx ON homework(student_id);