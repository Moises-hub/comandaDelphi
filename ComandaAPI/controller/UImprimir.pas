unit UImprimir;

interface
uses FireDAC.Comp.Client, Data.DB, System.SysUtils, Inifiles,Vcl.Printers,Vcl.Graphics,Classes,
  FireDAC.Stan.StorageBin,Vcl.ExtCtrls, uPrincipal;

type
TImprimir = class
  private
    FCLIENTE: STRING;
    FMESA: STRING;
    FCOMANDA: STRING;
    FID_PAINEL: INTEGER;
  public
    conexao : TFDConnection;
    constructor Create;
    destructor Destroy; override;
    function Imprimir(out erro: string): Boolean;
    property COMANDA :STRING read FCOMANDA write FCOMANDA;
    property CLIENTE:STRING read FCLIENTE write FCLIENTE;
    PROPERTY ID_PAINEL :INTEGER read FID_PAINEL write FID_PAINEL;

    property MESA :STRING read FMESA write FMESA;
end;


implementation

{ TImprimir }

function Crypt(Action, Src: String): String;
Label Fim;
var KeyLen : Integer;
       KeyPos : Integer;
       OffSet : Integer;
       Dest, Key : String;
       SrcPos : Integer;
       SrcAsc : Integer;
       TmpSrcAsc : Integer;
       Range : Integer;
begin
       if (Src = '') Then
       begin
               Result:= '';
               Goto Fim;
       end;
       Key := 'RARBOCODNENFAGAHLILJDKOLMSNSOCPCQHRHSMWMXIYIZTTZHK';
       Dest := '';
       KeyLen := Length(Key);
       KeyPos := 0;
       SrcPos := 0;
       SrcAsc := 0;
       Range := 256;
       if (Action = UpperCase('C')) then
       begin
               Randomize;
               OffSet := Random(Range);
               Dest := Format('%1.2x',[OffSet]);
               for SrcPos := 1 to Length(Src) do
               begin

                       SrcAsc := (Ord(Src[srcPos]) + OffSet) Mod 255;
                       if KeyPos < KeyLen then KeyPos := KeyPos + 1 else KeyPos := 1;

                       SrcAsc := SrcAsc Xor Ord(Key[KeyPos]);
                       Dest := Dest + Format('%1.2x',[srcAsc]);
                       OffSet := SrcAsc;
               end;
       end
       Else if (Action = UpperCase('D')) then
       begin
               OffSet := StrToInt('$' + copy(Src,1,2));//<--------------- adiciona o $ entra as aspas simples
               SrcPos := 3;
               repeat
                       SrcAsc := StrToInt('$' + copy(Src,SrcPos,2));//<--------------- adiciona o $ entra as aspas simples
                       if (KeyPos < KeyLen) Then KeyPos := KeyPos + 1 else KeyPos := 1;
                       TmpSrcAsc := SrcAsc Xor Ord(Key[KeyPos]);
                       if TmpSrcAsc <= OffSet then TmpSrcAsc := 255 + TmpSrcAsc - OffSet
                       else TmpSrcAsc := TmpSrcAsc - OffSet;
                       Dest := Dest + Chr(TmpSrcAsc);
                       OffSet := SrcAsc;
                       SrcPos := SrcPos + 2;
               until (SrcPos >= Length(Src));
       end;
       Result:= Dest;
Fim:
end;

constructor TImprimir.Create;
VAR
file_config : TInifile;
begin
 file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');


                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();
end;

destructor TImprimir.Destroy;
begin
  conexao.Free;
  inherited;
end;

function TImprimir.Imprimir(out erro: string): Boolean;
VAR
  linha, coluna,Tamanho,I: integer;
 tab_impressora:TFDquery;
  Printer: TPrinter;
  qry : TFDQuery;

begin






                                   tab_impressora:=tfdquery.Create(nil);
                                   tab_impressora.Connection:=conexao;
                                   tab_impressora.SQL.Text:='SELECT distinct(ID_IMPRESSORA)' +
                                                            '       from COMANDA_PAINEL_ITENS ' +
                                                            ' inner join produtos on produtos.id_produto =   COMANDA_PAINEL_ITENS.COD_PROD ' +
                                                            ' where COMANDA_PAINEL_ITENS.id_painel =:ID_PAINEL ' +
                                                            ' order by ID_IMPRESSORA';
                                    tab_impressora.ParamByName('id_painel').AsInteger :=FID_PAINEL;
                                    tab_impressora.open;
                                    tab_impressora.first;

                                  while not Tab_Impressora.eof do
                                  begin


                                                         qry := tfdquery.create(nil);
                                                         qry.Connection:=conexao;
                                                         qry.sql.text:='SELECT  produtos.codigo_barra||''-'' as codbarras, ' +
                                                                                'COMANDA_PAINEL_ITENS.descricao, ' +
                                                                                'COMANDA_PAINEL_ITENS.qnt, ' +
                                                                                'COMANDA_PAINEL_ITENS.detalhe ' +
                                                                                'from COMANDA_PAINEL_ITENS ' +
                                                                                'inner join produtos on produtos.id_produto =   COMANDA_PAINEL_ITENS.COD_PROD ' +
                                                                                'where COMANDA_PAINEL_ITENS.id_painel =:ID_PAINEL AND ID_IMPRESSORA =:ID_IMPRESSORA';
                                                         qry.ParamByName('id_painel').AsInteger :=FID_PAINEL;
                                                         qry.ParamByName('ID_IMPRESSORA').AsInteger :=Tab_Impressora.FieldByName('id_impressora').AsInteger;
                                                         qry.open;




                                                         if qry.RecordCount<>0 then
                                                         begin
                                                              Printer:= TPrinter.Create;
                                                              Printer.PrinterIndex:=Tab_Impressora.FieldByName('id_impressora').AsInteger;
                                                              Printer.BeginDoc;
                                                              Printer.Canvas.StretchDraw(Rect(450, 0, 550, 90),Frm_Principal.Image2.Picture.Graphic);
                                                              Printer.Canvas.Font.Size := 8;

                                                             Printer.Canvas.TextOut(20,1,'MESA');
                                                             Printer.Canvas.Font.Size := 15;
                                                             Printer.Canvas.TextOut(23,35,FMESA);

                                                             Printer.Canvas.Pen.Width := 5;
                                                             Printer.Canvas.Font.Name := 'Times New Roman';
                                                             Printer.Canvas.Font.Size := 10;
                                                             Linha := 90;
                                                             Coluna:= 20;


                                                            Printer.Canvas.TextOut(Coluna,Linha,'_____________________________________________');
                                                            Tamanho := Printer.Canvas.TextWidth('a');


                                                            Linha := Linha - Printer.Canvas.Font.Height + 5 ;
                                                            Printer.Canvas.Font.Size := 12;
                                                            Printer.Canvas.TextOut(Coluna,Linha,COPY(FCLIENTE,1,30));
                                                            Linha := Linha - Printer.Canvas.Font.Height + 5 ;
                                                            Printer.Canvas.Font.Size := 7;
                                                            Printer.Canvas.TextOut(Coluna,Linha,'COMANDA: '+FCOMANDA+'       '+FormatDateTime('dd"/"mm"/"yyyy" "hh":"mm',now));
                                                            Linha := Linha - Printer.Canvas.Font.Height;
                                                            Printer.Canvas.TextOut(Coluna,Linha,'_____________________________________________');
                                                            Linha := Linha - Printer.Canvas.Font.Height+5;
                                                            Printer.Canvas.Font.Size := 10;
                                                            Printer.Canvas.Font.Style:=Printer.Canvas.Font.Style + [fsbold];
                                                            Printer.Canvas.TextOut(Coluna,Linha,'CÓD');
                                                            Printer.Canvas.TextOut(90,Linha,'DESCRIÇÃO');
                                                            Printer.Canvas.TextOut(500,Linha,'QNT');

                                                            Linha := Linha - Printer.Canvas.Font.Height+7;
                                                            Printer.Canvas.Font.Size := 12;
                                                            Printer.Canvas.Font.Style:=Printer.Canvas.Font.Style - [fsbold];






                                                           qry.first;
                                                           while not qry.eof do
                                                           begin


                                                              Printer.Canvas.TextOut(COLUNA,Linha,QRY.FieldByName('codbarras').AsString+
                                                              copy(QRY.FieldByName('descricao').AsString,1,20));

                                                               Printer.Canvas.TextOut(520,Linha,QRY.FieldByName('qnt').AsString);
                                                               if LENGTH(QRY.FieldByName('detalhe').AsString)>0 then
                                                                 begin
                                                                 Linha := Linha - Printer.Canvas.Font.Height+3;
                                                                 Printer.Canvas.TextOut(20,Linha,'obs.: '+QRY.FieldByName('detalhe').AsString);

                                                                 end;
                                                                Linha := Linha - Printer.Canvas.Font.Height+10;
                                                                qry.Next;
                                                                END;

                                                              Printer.Canvas.TextOut(Coluna,Linha,'_____________________________________________');
                                                              Linha := Linha - Printer.Canvas.Font.Height+10;
                                                              Printer.Canvas.Font.Size := 8;
                                                              Printer.Canvas.StretchDraw(Rect(coluna, Linha, 80, linha+45),Frm_Principal.Image1.Picture.Graphic);
                                                              Printer.Canvas.TextOut(90,Linha+10,'COLISEU SISTEMAS  (67) 3423-2227');
                                                              Printer.EndDoc;
                                                              Printer.Free;
                                                         end;

                                   Tab_Impressora.next;
                                  end;
                                  Tab_Impressora.free;

END;



end.
