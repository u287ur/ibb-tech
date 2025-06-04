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

interface Loan {
  id: number;
  student_name: string;
  book_title: string;
  loan_date: string;
  return_date: string | null;
  is_returned: boolean;
}

const Loans = () => {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const token = localStorage.getItem('token');
  const userRole = localStorage.getItem('userRole');

  // ✅ API base URL environment değişkeninden okunuyor
  const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";

  const { data: loans, isLoading } = useQuery({
    queryKey: ['loans'],
    queryFn: async () => {
      console.log('Fetching loans...');
      const response = await fetch(`${API_BASE_URL}/api/loans/`, {
        headers: {
          'Authorization': `Token ${token}`,
        },
      });
      if (!response.ok) {
        throw new Error('Ödünç kayıtları yüklenirken hata oluştu');
      }
      const data = await response.json();
      console.log('Fetched loans:', data);
      return data;
    },
  });

  const returnBookMutation = useMutation({
    mutationFn: async (loanId: number) => {
      const response = await fetch(`${API_BASE_URL}/api/loans/${loanId}/return_book/`, {
        method: 'POST',
        headers: {
          'Authorization': `Token ${token}`,
        },
      });
      if (!response.ok) {
        throw new Error('Kitap iade edilirken hata oluştu');
      }
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['loans'] });
      toast({
        title: "Başarılı",
        description: "Kitap başarıyla iade edildi",
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
      <h1 className="text-3xl font-bold mb-6">Ödünç İşlemleri</h1>
      
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Öğrenci</TableHead>
              <TableHead>Kitap</TableHead>
              <TableHead>Veriliş Tarihi</TableHead>
              <TableHead>İade Tarihi</TableHead>
              <TableHead>Durum</TableHead>
              {userRole === 'admin' && <TableHead>İşlem</TableHead>}
            </TableRow>
          </TableHeader>
          <TableBody>
            {loans?.map((loan: Loan) => (
              <TableRow key={loan.id}>
                <TableCell>{loan.student_name}</TableCell>
                <TableCell>{loan.book_title}</TableCell>
                <TableCell>{new Date(loan.loan_date).toLocaleDateString('tr-TR')}</TableCell>
                <TableCell>
                  {loan.return_date ? new Date(loan.return_date).toLocaleDateString('tr-TR') : '-'}
                </TableCell>
                <TableCell>
                  {loan.is_returned ? 'İade Edildi' : 'Ödünç Verildi'}
                </TableCell>
                {userRole === 'admin' && (
                  <TableCell>
                    {!loan.is_returned && (
                      <Button
                        onClick={() => returnBookMutation.mutate(loan.id)}
                        size="sm"
                      >
                        İade Al
                      </Button>
                    )}
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

export default Loans;
