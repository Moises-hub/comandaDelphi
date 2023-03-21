unit ULancamento;

interface
uses FireDAC.Comp.Client, Data.DB, System.SysUtils, Inifiles,System.Classes;

type
TLancamento = class
private
   FID_CLIENTE: Integer;
    FID_COMANDA: INTEGER;
    FID_PRODUTO: INTEGER;
    FDETALHE: STRING;
    FCOMANDA: STRING;
    FQNT: REAL;
    FCODBARRAS: STRING;
    FID_PAINEL: INTEGER;
    FID_IMPRESSORA: INTEGER;
    FMESA: STRING;
  public
    conexao : TFDConnection;
    constructor Create;
    destructor Destroy; override;
    function Inserir(out erro: string): Boolean;
    PROPERTY ID_CLIENTE :INTEGER read FID_CLIENTE write FID_CLIENTE;
    PROPERTY ID_COMANDA :INTEGER read FID_COMANDA write FID_COMANDA;
    property COMANDA :STRING read FCOMANDA write FCOMANDA;
    property CODBARRAS :STRING read FCODBARRAS write FCODBARRAS;
    PROPERTY ID_PRODUTO :INTEGER read FID_PRODUTO write FID_PRODUTO;
    PROPERTY QNT :REAL read FQNT write FQNT;
    property DETALHE :STRING read FDETALHE write FDETALHE;
    PROPERTY ID_PAINEL :INTEGER read FID_PAINEL write FID_PAINEL;
    PROPERTY ID_IMPRESSORA :INTEGER read FID_IMPRESSORA write FID_IMPRESSORA;
    property MESA :STRING read FMESA write FMESA;

end;

implementation

{ TLancamento }

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

constructor TLancamento.Create;
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

destructor TLancamento.Destroy;
begin
   conexao.Free;
  inherited;
end;

function TLancamento.Inserir(out erro: string): Boolean;
var
    qry : TFDQuery;
begin
     qry := tfdquery.create(nil);
     qry.Connection:=conexao;
     qry.sql.text:='select count(ID_PRODUTO) from  comanda_lancamento where ID_PRODUTO =:ID_PRODUTO and ID_lancamento =:ID_PAINEL';
     QRY.ParamByName('ID_PRODUTO').AsInteger:=FID_PRODUTO;
     QRY.ParamByName('ID_PAINEL').AsInteger:=FID_PAINEL;
     QRY.Open();
     if QRY.FieldByName('COUNT').AsInteger = 0 then
     BEGIN

     QRY.CLOSE;


         qry.sql.text:='insert into comanda_lancamento (id_cliente,' +
                       '                                id, ' +
                       '                                id_comanda, ' +
                       '                                COD_BARRAS, ' +
                       '                                ID_PRODUTO, ' +
                       '                                qnt, ' +
                       '                                valorunt, ' +
                       '                                valor, ' +
                       '                                id_local, ' +
                       '                                comanda, ' +
                       '                                status, ' +
                       '                                data_hora, ' +
                       '                                DETALHE, ' +
                       '                                ID_DEPTO, ' +
                       '                                ID_LANCAMENTO) '+
                       ' VALUES(:id_cliente, '+
                       '(select gen_id(COMANDA_LANCAMENTO_ID,1) from RDB$DATABASE), ' +
                       ':ID_COMANDA, ' +
                       ':CODBARRAS, ' +
                       ':ID_PRODUTO, '+
                       ':QNT, ' +
                       '(SELECT produto_precos.preco_tabela FROM produto_precos WHERE produto_precos.ID_PRODUTO =:ID_PRODUTO and produto_precos.ativo = 1), '+
                       ':QNT*(SELECT produto_precos.preco_tabela FROM produto_precos WHERE produto_precos.ID_PRODUTO =:ID_PRODUTO and produto_precos.ativo = 1), '+
                       '1, '+
                       ':COMANDA, ' +
                       '1, ' +
                       'current_timestamp, ' +
                       ':DETALHE, ' +
                       'COALESCE((select ID_DEPARTAMENTO FROM COMANDA_CONFIG),1), '+
                       ':ID_PAINEL)';

         QRY.ParamByName('ID_CLIENTE').AsInteger:=FID_CLIENTE;
         QRY.ParamByName('ID_COMANDA').AsInteger:=FID_COMANDA;
         QRY.ParamByName('CODBARRAS').AsString:=FCODBARRAS;
         QRY.ParamByName('ID_PRODUTO').AsInteger:=FID_PRODUTO;
         QRY.ParamByName('QNT').AsFloat:=FQNT;
         QRY.ParamByName('COMANDA').AsString:=FCOMANDA;
         QRY.ParamByName('DETALHE').AsString:=FDETALHE;
         QRY.ParamByName('ID_PAINEL').AsInteger:=FID_PAINEL;
         QRY.ExecSQL;
         conexao.Commit;




              qry.sql.text:='insert INTO comanda_painel_itens (ID,ID_PAINEL,DESCRICAO,QNT,DETALHE,COD_PROD,id_impressora)' +
                            '           VALUES((SELECT GEN_ID(comanda_painel_itens_id,1) FROM RDB$DATABASE), ' +
                            '                  :ID_PAINEL, ' +
                            '                  (select PRODUTOS.descricao from produtos where produtos.id_produto =:id_produto), ' +
                            '                  :QNT, ' +
                            '                  :DETALHE, ' +
                            '                  :id_produto, ' +
                            '                  :id_impressora) ';
            QRY.ParamByName('DETALHE').AsString:=FDETALHE;
            QRY.ParamByName('ID_PAINEL').AsInteger:=FID_PAINEL;
            QRY.ParamByName('ID_IMPRESSORA').AsInteger:=FID_IMPRESSORA;
            QRY.ExecSQL;
            conexao.Commit;





         QRY.Free;
         END;

end;

end.
