export interface Course {
  id: number;
  name: string;
  path: string;
  createdDate: Date;
  items?: CourseItem[];
}

export interface CourseItem {
  id: number;
  courseId: number;
  parentId?: number;
  name: string;
  path: string;
  type: string;
  extension: string;
  size: number;
  children?: CourseItem[];
}
