export interface Category {
  id: number;
  name: string;
  path: string;
  createdDate: Date;
  courses?: Course[];
}

export interface Course {
  id: number;
  categoryId: number;
  categoryName?: string;
  name: string;
  path: string;
  createdDate: Date;
  category?: Category;
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
