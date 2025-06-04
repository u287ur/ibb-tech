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

interface Book {
  id: number;
  title: string;
  author: string;
  is_available: boolean;
}

const Books = () => {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const userRole = localStorage.getItem('userRole');
  const token = localStorage.getItem('token');
  const [newBook, setNewBook] = useState({ title: '', author: '' });
  const [isDialogOpen, setIsDialogOpen] = useState(false);

  // ✅ API base URL, .env dosyasından okunur
  const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";

  const { data: books, isLoading } = useQuery({
    queryKey: ['books'],
    queryFn: async () => {
      console.log('Fetching books...');
      const response = await fetch(`${API_BASE_URL}/api/books/`, {
        headers: {
          'Authorization': `Token ${token}`,
        },
      });
      if (!response.ok) {
        throw new Error('Kitaplar yüklenirken hata oluştu');
      }
      const data = await response.json();
      console.log('Fetched books:', data);
      return data;
    },
  });

  const addBookMutation = useMutation({
    mutationFn: async (bookData: { title: string; author: string }) => {
      const response = await fetch(`${API_BASE_URL}/api/books/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Token ${token}`,
        },
        body: JSON.stringify(bookData),
      });
      if (!response.ok) {
        throw new Error('Kitap eklenirken hata oluştu');
      }
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] });
      toast({
        title: "Başarılı",
        description: "Kitap başarıyla eklendi",
      });
      setNewBook({ title: '', author: '' });
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

  const borrowMutation = useMutation({
    mutationFn: async (bookId: number) => {
      const response = await fetch(`${API_BASE_URL}/api/loans/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Token ${token}`,
        },
        body: JSON.stringify({
          book_id: bookId,
          loan_date: new Date().toISOString().split('T')[0],
        }),
      });
      if (!response.ok) {
        throw new Error('Kitap ödünç alınırken hata oluştu');
      }
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] });
      toast({
        title: "Başarılı",
        description: "Kitap başarıyla ödünç alındı",
      });
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
        <h1 className="text-3xl font-bold">Kitaplar</h1>
        {userRole === 'admin' && (
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button>Yeni Kitap Ekle</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Yeni Kitap Ekle</DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div>
                  <label className="text-sm font-medium">Kitap Adı</label>
                  <Input
                    value={newBook.title}
                    onChange={(e) => setNewBook({ ...newBook, title: e.target.value })}
                    placeholder="Kitap adını girin"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium">Yazar</label>
                  <Input
                    value={newBook.author}
                    onChange={(e) => setNewBook({ ...newBook, author: e.target.value })}
                    placeholder="Yazarın adını girin"
                  />
                </div>
                <Button 
                  onClick={() => addBookMutation.mutate(newBook)}
                  disabled={!newBook.title || !newBook.author}
                >
                  Ekle
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        )}
      </div>
      
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Başlık</TableHead>
              <TableHead>Yazar</TableHead>
              <TableHead>Durum</TableHead>
              {userRole === 'student' && <TableHead>İşlem</TableHead>}
            </TableRow>
          </TableHeader>
          <TableBody>
            {books?.map((book: Book) => (
              <TableRow key={book.id}>
                <TableCell>{book.title}</TableCell>
                <TableCell>{book.author}</TableCell>
                <TableCell>
                  {book.is_available ? 'Müsait' : 'Ödünç Verildi'}
                </TableCell>
                {userRole === 'student' && (
                  <TableCell>
                    <Button
                      onClick={() => borrowMutation.mutate(book.id)}
                      disabled={!book.is_available}
                      variant={book.is_available ? "default" : "secondary"}
                    >
                      {book.is_available ? 'Ödünç Al' : 'Mevcut Değil'}
                    </Button>
                  </TableCell>
                )}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );
};

export default Books;
