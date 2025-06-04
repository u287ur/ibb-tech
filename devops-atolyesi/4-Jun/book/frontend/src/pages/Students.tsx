import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { useToast } from "@/components/ui/use-toast";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { useState } from "react";

interface Student {
  id: number;
  name: string;
  student_number: string;
  email: string;
}

const Students = () => {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const token = localStorage.getItem('token');
  const [newStudent, setNewStudent] = useState({
    name: '',
    email: '',
    password: '',
    student_number: ''
  });
  const [isDialogOpen, setIsDialogOpen] = useState(false);

  // 🇬🇧 Fetch all students from backend API
  const { data: students, isLoading } = useQuery({
    queryKey: ['students'],
    queryFn: async () => {
      console.log('Fetching students...');
      const response = await fetch(`${import.meta.env.VITE_API_BASE_URL}/api/students/`, {
        headers: {
          'Authorization': `Token ${token}`,
        },
      });
      if (!response.ok) {
        throw new Error('Öğrenciler yüklenirken hata oluştu');
      }
      const data = await response.json();
      console.log('Fetched students:', data);
      return data;
    },
  });

  // 🇬🇧 Add a new student to backend
  const addStudentMutation = useMutation({
    mutationFn: async (studentData: typeof newStudent) => {
      const response = await fetch(`${import.meta.env.VITE_API_BASE_URL}/api/students/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Token ${token}`,
        },
        body: JSON.stringify(studentData),
      });
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Öğrenci eklenirken hata oluştu');
      }
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['students'] });
      toast({
        title: "Başarılı",
        description: "Öğrenci başarıyla eklendi",
      });
      setNewStudent({
        name: '',
        email: '',
        password: '',
        student_number: ''
      });
      setIsDialogOpen(false);
    },
    onError: (error: Error) => {
      toast({
        variant: "destructive",
        title: "Hata",
        description: error.message,
      });
    },
  });

  if (isLoading) {
    return <div className="container mx-auto py-8">Yükleniyor...</div>;
  }

  return (
    <div className="container mx-auto py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Öğrenciler</h1>
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button>Yeni Öğrenci Ekle</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Yeni Öğrenci Ekle</DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium">Ad Soyad</label>
                <Input
                  value={newStudent.name}
                  onChange={(e) => setNewStudent({ ...newStudent, name: e.target.value })}
                  placeholder="Ad ve soyadı girin"
                />
              </div>
              <div>
                <label className="text-sm font-medium">E-posta</label>
                <Input
                  type="email"
                  value={newStudent.email}
                  onChange={(e) => setNewStudent({ ...newStudent, email: e.target.value })}
                  placeholder="E-posta adresini girin"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Şifre</label>
                <Input
                  type="password"
                  value={newStudent.password}
                  onChange={(e) => setNewStudent({ ...newStudent, password: e.target.value })}
                  placeholder="Şifre girin"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Öğrenci Numarası</label>
                <Input
                  value={newStudent.student_number}
                  onChange={(e) => setNewStudent({ ...newStudent, student_number: e.target.value })}
                  placeholder="Öğrenci numarasını girin"
                />
              </div>
              <Button 
                onClick={() => addStudentMutation.mutate(newStudent)}
                disabled={!newStudent.name || !newStudent.email || !newStudent.password || !newStudent.student_number}
              >
                Ekle
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>
      
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Ad Soyad</TableHead>
              <TableHead>Öğrenci Numarası</TableHead>
              <TableHead>E-posta</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {students?.map((student: Student) => (
              <TableRow key={student.id}>
                <TableCell>{student.name}</TableCell>
                <TableCell>{student.student_number}</TableCell>
                <TableCell>{student.email}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );
};

export default Students;
