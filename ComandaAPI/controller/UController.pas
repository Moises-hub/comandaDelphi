unit UController;

interface
uses  Horse,System.JSON,Horse.CORS,System.SysUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
      FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,FireDAC.Stan.Async,
      FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,FireDAC.Comp.Client, inifiles,FireDAC.Stan.Def,FireDAC.Phys.FBDef,
      FireDAC.Phys, FireDAC.Phys.IBBase, FireDAC.Phys.FB,System.Classes,Vcl.Printers,Vcl.Graphics,
  ULancamento,  UImprimir,FireDAC.Stan.StorageBin;


procedure Registry;
procedure lanca_produto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure lanca_comanda(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure lancar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure get_pedidos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure get_itens(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure get_categorias(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure get_produtos(Req: THorseRequest; Res: THorseResponse; Next: TProc);




implementation

procedure Registry;
  begin
  THorse.GET('/lanca_produto/:codigo_barras',lanca_produto);
  THorse.GET('/lancar_comanda/:comanda/:tipo',lanca_comanda);
  THorse.Post('/lancar',lancar);
  THorse.GET('/getpedido/:comanda',get_pedidos);
  THorse.GET('/getitens/:comanda/:lancamento',get_itens);
  THorse.GET('/getcategorias/',get_categorias);
  THorse.GET('/getprodutos/:categoria',get_produtos);

  end;


function retirarZeros(texto: string): string;
begin
   result := texto;
   while ( pos( '0', result ) = 1 ) do begin
      result := copy( result, 2, length( result ) );
   end;
end;





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
procedure get_produtos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
query_listprod : TFDQuery;
objeto: TJSONObject;
Llistprod  : TJSONArray;
conexao : TFDConnection;
file_config : TInifile;
BEGIN
     if FileExists(ExtractFilePath(ParamStr(0))+'config.dll') then
       begin
                file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');


                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();
                   query_listprod:=TFDQuery.Create(NIL);
                   query_listprod.Connection:=conexao;
                   query_listprod.Close;

                     query_listprod.SQL.Text:='SELECT produtos.codigo_barra, '+
                                              '       produtos.descricao, ' +
                                              '       produto_precos.preco_tabela ' +
                                              '       FROM PRODUTOS' +
                                              ' inner join produto_precos on produto_precos.id_produto = produtos.id_produto and produto_precos.ativo = 1 ' +
                                              ' WHERE produtos.id_categoria =:categoria ' +
                                              ' order by produtos.descricao';

                     query_listprod.ParamByName('categoria').AsString:=Req.Params['categoria'];
                     query_listprod.open;




                        Llistprod     := TJSONArray.Create;
                      if query_listprod.RecordCount >0 then
                       begin
                        query_listprod.first;
                        while NOT query_listprod.Eof do
                        BEGIN
                         objeto := TJSONObject.Create;

                         objeto.AddPair('codigo_barra',query_listprod.FieldByName('codigo_barra').AsString);
                         objeto.AddPair('descricao',query_listprod.FieldByName('descricao').AsString);
                         objeto.AddPair('preco',StringReplace(FloatToStrf(query_listprod.FieldByName('preco_tabela').Asfloat,ffFixed,15,2),',','.',[rfReplaceAll]));
                         Llistprod.Add(objeto);
                         query_listprod.NEXT;
                        END;
                       end;


                        Res.Send<TJSONArray>(Llistprod);
                        query_listprod.FREE;
                        conexao.Free;
                        file_config.Free;




       end;



end;
procedure get_categorias(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
query_categorias : TFDQuery;
objeto: TJSONObject;
Lcategorias  : TJSONArray;
conexao : TFDConnection;
file_config : TInifile;
BEGIN
     if FileExists(ExtractFilePath(ParamStr(0))+'config.dll') then
       begin
                file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');






                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();
                   query_categorias:=TFDQuery.Create(NIL);
                   query_categorias.Connection:=conexao;
                   query_categorias.Close;

                     query_categorias.SQL.Text:='select distinct(classificacao),' +
                                                '       id_categoria, '+
                                                '       DESCRICAO from CATEGORIAS' +
                                                ' where classificacao is not null ' +
                                                ' and classificacao <> '''' and pai ' +
                                                ' is not null order by descricao';


                     query_categorias.open;




                        Lcategorias     := TJSONArray.Create;
                      if query_categorias.RecordCount >0 then
                       begin
                        query_categorias.first;
                        while NOT query_categorias.Eof do
                        BEGIN
                         objeto := TJSONObject.Create;
                         objeto.AddPair('id_categoria',query_categorias.FieldByName('id_categoria').AsString);
                         objeto.AddPair('classificacao',query_categorias.FieldByName('classificacao').AsString);
                         objeto.AddPair('descricao',query_categorias.FieldByName('descricao').AsString);

                         Lcategorias.Add(objeto);
                         query_categorias.NEXT;
                        END;
                       end;


                        Res.Send<TJSONArray>(Lcategorias);
                        query_categorias.FREE;
                        conexao.Free;
                        file_config.Free;




       end;



end;




procedure get_itens(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
query_Itens : TFDQuery;
objeto: TJSONObject;
LItens  : TJSONArray;
conexao : TFDConnection;
file_config : TInifile;
BEGIN
     if FileExists(ExtractFilePath(ParamStr(0))+'config.dll') then
       begin
                file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');






                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();
                   query_Itens:=TFDQuery.Create(NIL);
                   query_Itens.Connection:=conexao;
                   query_Itens.Close;


                    if Req.Params['lancamento'] = '0' then

                   begin
                     query_Itens.SQL.Text:='select COMANDA_LANCAMENTO.cod_barras,' +
                                           '       COMANDA_LANCAMENTO.id_LANCAMENTO, ' +
                                           '       produtos.descricao, ' +
                                           '       coalesce(categorias.classificacao,0)classificacao, '+
                                           '       sum(COMANDA_LANCAMENTO.valor)total, ' +
                                           '       sum(COMANDA_LANCAMENTO.qnt)qnt ' +
                                           '       from COMANDA_LANCAMENTO ' +
                                           '       join produtos on  produtos.id_produto = COMANDA_LANCAMENTO.id_produto ' +
                                           '       left join categorias on categorias.id_categoria = produtos.id_categoria '+
                                           ' where (select comanda_cli.status from comanda_cli where comanda_cli.id_cliente = COMANDA_LANCAMENTO.id_cliente)=1 ' +
                                           'and   COMANDA_LANCAMENTO.status = 1 and comanda_lancamento.comanda =:comanda  ' +
                                           '       group by COMANDA_LANCAMENTO.cod_barras, ' +
                                           '       COMANDA_LANCAMENTO.id_LANCAMENTO,' +
                                           '       produtos.descricao,categorias.classificacao';

                     query_Itens.ParamByName('comanda').AsString :=Req.Params['comanda'];

                   end
                   else
                      begin
                         query_Itens.SQL.Text:='select COMANDA_LANCAMENTO.cod_barras,' +
                                           '       COMANDA_LANCAMENTO.id_LANCAMENTO, ' +
                                           '       produtos.descricao, ' +
                                           '       coalesce(categorias.classificacao,0) classificacao, '+
                                           '       sum(COMANDA_LANCAMENTO.valor)total, ' +
                                           '       sum(COMANDA_LANCAMENTO.qnt)qnt ' +
                                           '       from COMANDA_LANCAMENTO ' +
                                           '       join produtos on  produtos.id_produto = COMANDA_LANCAMENTO.id_produto ' +
                                           '       left join categorias on categorias.id_categoria = produtos.id_categoria '+
                                           ' where id_LANCAMENTO =:id_lancamento and '+
                                           '(select comanda_cli.status from comanda_cli where comanda_cli.id_cliente = COMANDA_LANCAMENTO.id_cliente)=1 ' +
                                           'and   COMANDA_LANCAMENTO.status = 1 and comanda_lancamento.comanda =:comanda  ' +
                                           '       group by COMANDA_LANCAMENTO.cod_barras, ' +
                                           '       COMANDA_LANCAMENTO.id_LANCAMENTO,' +
                                           '       produtos.descricao,categorias.classificacao';

                         query_Itens.ParamByName('comanda').AsString :=Req.Params['comanda'];
                         query_Itens.ParamByName('id_lancamento').AsString :=Req.Params['lancamento'];

                       end;


                             query_Itens.open;

                        LItens     := TJSONArray.Create;
                      if query_Itens.RecordCount >0 then
                       begin
                        query_Itens.first;
                        while NOT query_Itens.Eof do
                        BEGIN
                         objeto := TJSONObject.Create;
                         objeto.AddPair('lancamento',query_Itens.FieldByName('id_lancamento').AsString);
                         objeto.AddPair('cod_barras',query_Itens.FieldByName('cod_barras').AsString);
                         objeto.AddPair('classificacao',query_Itens.FieldByName('classificacao').AsString);
                         objeto.AddPair('descricao',query_Itens.FieldByName('descricao').AsString);
                         objeto.AddPair('qnt',StringReplace(FloatToStrf(query_Itens.FieldByName('qnt').Asfloat,ffFixed,15,2),',','.',[rfReplaceAll]));
                         objeto.AddPair('total',StringReplace(FloatToStrf(query_Itens.FieldByName('total').Asfloat,ffFixed,15,2),',','.',[rfReplaceAll]));

                         LItens.Add(objeto);
                         query_Itens.NEXT;
                        END;
                       end;


                        Res.Send<TJSONArray>(LItens);
                        query_Itens.FREE;
                        conexao.Free;
                        file_config.Free;




       end;
END;




procedure get_pedidos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
query_lancamento : TFDQuery;
objeto: TJSONObject;
Llancamento  : TJSONArray;
conexao : TFDConnection;
file_config : TInifile;
BEGIN
     if FileExists(ExtractFilePath(ParamStr(0))+'config.dll') then
       begin
                file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');






                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();
                   query_lancamento:=TFDQuery.Create(NIL);
                   query_lancamento.Connection:=conexao;
                   query_lancamento.Close;

                     query_lancamento.SQL.Text:='select sum(COMANDA_LANCAMENTO.valor) total,' +
                                                '       COMANDA_LANCAMENTO.id_lancamento, ' +
                                                '       cast(comanda_lancamento.data_hora as date)data'+
                                                '       from COMANDA_LANCAMENTO ' +
                                                '       join produtos on  produtos.id_produto = COMANDA_LANCAMENTO.id_produto ' +
                                                '       join comanda_cli on comanda_cli.id_cliente = COMANDA_LANCAMENTO.id_cliente '+
                                                'where    comanda_cli.status =1 ' +
                                                'and   COMANDA_LANCAMENTO.status = 1 and comanda_lancamento.comanda =:comanda  ' +
                                                'group by COMANDA_LANCAMENTO.id_lancamento,cast(comanda_lancamento.data_hora as date) '+
                                                'order by cast(comanda_lancamento.data_hora as date)desc';

                     query_lancamento.ParamByName('comanda').AsString :=Req.Params['comanda'];
                     query_lancamento.open;




                        Llancamento     := TJSONArray.Create;
                      if query_lancamento.RecordCount >0 then
                       begin
                        query_lancamento.first;
                        while NOT query_lancamento.Eof do
                        BEGIN
                         objeto := TJSONObject.Create;
                         objeto.AddPair('total',StringReplace(FloatToStrf(query_lancamento.FieldByName('total').Asfloat,ffFixed,15,2),',','.',[rfReplaceAll]));
                         objeto.AddPair('lancamento',query_lancamento.FieldByName('id_lancamento').AsString);
                         objeto.AddPair('data',StringReplace(query_lancamento.FieldByName('data').AsString,'/','-',[rfReplaceAll]));
                         Llancamento.Add(objeto);
                         query_lancamento.NEXT;
                        END;
                       end;


                        Res.Send<TJSONArray>(Llancamento);
                        query_lancamento.FREE;
                        conexao.Free;
                        file_config.Free;




       end;



end;





procedure lancar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
query: TFDQuery;
conexao : TFDConnection;
itlANCAMENTO : TLancamento;
body  : TJsonValue;
ArrayElement: TJSonValue;
i : integer;
jsa: TJSONArray;
erro : string;
file_config:TIniFile;
objeto : TJSONObject;
Lid     : TJSONArray;
comanda,cliente,mesa,idpainel : string;
imprimir : TImprimir;
 tab_impressora:TFDMemTable;
 Printer: TPrinter;
  Tab_ListImpressora:TFDMemTable;
begin


                         Tab_ListImpressora:=TFDMemTable.Create(nil);
                         Tab_ListImpressora.FieldDefs.Add('INDEX', ftInteger, 0, false);
                         Tab_ListImpressora.FieldDefs.Add('IMPRESSORA', ftString, 50, false);
                         Tab_ListImpressora.Open;
                         Printer:=TPrinter.Create;
                                  try
                                    for i := 0 to Printer.Printers. Count - 1 do
                                    begin

                                       Tab_ListImpressora.Insert;
                                       Tab_ListImpressora.FieldByName('index').AsInteger:=i;
                                       Tab_ListImpressora.FieldByName('impressora').Text:=Printer.Printers.Strings[i];
                                       Tab_ListImpressora.post;

                                    end;
                                    finally
                                    Printer.free;
                                  end;



                tab_impressora:=TFDMemTable.Create(nil);
                     if FileExists(ExtractFilePath(ParamStr(0))+'configImpressora.fds') then
                      begin
                        tab_impressora.LoadFromFile(ExtractFilePath(ParamStr(0))+'configImpressora.fds');
                      end;
                      Tab_Impressora.Open;


           Tab_Impressora.First;
      while  not Tab_Impressora.Eof do
          begin
          if  Tab_ListImpressora.Locate('impressora',Tab_Impressora.FieldByName('nome').AsString,[loCaseInsensitive]) then
            begin
            Tab_Impressora.Edit;
            Tab_Impressora.FieldByName('id_impressora').AsInteger:= Tab_ListImpressora.FieldByName('index').AsInteger;
            Tab_Impressora.Post;
            end
            else
            begin

            Tab_Impressora.Edit;
            Tab_Impressora.FieldByName('id_impressora').AsInteger:= -1;
            Tab_Impressora.Post;
            end;
            Tab_Impressora.next;
          end;



           Tab_ListImpressora.free;














    // Conexao com o banco...
                try
                    itlANCAMENTO := TLancamento.Create;

                   file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');
                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();








                except
                         Lid:=TJSONArray.Create;
                         objeto := TJSONObject.Create;
                         objeto.AddPair('executado','Erro ao conectar com o banco');

                         Lid.Add(objeto);
                         Res.Send<TJSONArray>(Lid);

                    res.Send('Erro ao conectar com o banco').Status(500);
                    exit;
                end;


                try
                    try




                          body := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(req.Body), 0) as TJsonValue;

                          jsa := body as TJSONArray;

                          ArrayElement := jsa;






                          i:=0;
                         for ArrayElement in jsa do
                              begin
                              itlANCAMENTO.ID_CLIENTE :=StrToInt(ArrayElement.GetValue<String>('id_cliente', ''));
                              itlANCAMENTO.ID_COMANDA := StrToInt(ArrayElement.GetValue<String>('id_comanda', ''));
                              itlANCAMENTO.ID_PRODUTO := StrToInt(ArrayElement.GetValue<String>('id_produto', ''));
                              itlANCAMENTO.COMANDA := retirarZeros(ArrayElement.GetValue<String>('comanda', ''));
                              comanda := ArrayElement.GetValue<String>('comanda', '');
                              cliente := ArrayElement.GetValue<String>('cliente', '');
                              itlANCAMENTO.CODBARRAS := ArrayElement.GetValue<String>('codbarras', '');
                              itlANCAMENTO.QNT := strtofloat(StringReplace(ArrayElement.GetValue<String>('qnt', ''),'.',',',[rfReplaceAll]));
                              itlANCAMENTO.DETALHE := ArrayElement.GetValue<String>('detalhe', '');
                              itlANCAMENTO.ID_PAINEL := StrToInt(ArrayElement.GetValue<String>('id_lancamento', ''));
                              idpainel  :=ArrayElement.GetValue<String>('id_lancamento', '');
                              mesa := ArrayElement.GetValue<String>('mesa', '');

                               if LENGTH(ArrayElement.GetValue<String>('classificacao', ''))<>0 then
                                    BEGIN
                                    IF Tab_Impressora.Locate('id_classificacao',ArrayElement.GetValue<String>('classificacao', ''),[loCaseInsensitive])THEN
                                        itlANCAMENTO.ID_IMPRESSORA := Tab_Impressora.FieldByName('id_impressora').AsInteger;

                                    END;


                              itlANCAMENTO.Inserir(erro);
                              end;




                      imprimir := TImprimir.Create;
                      imprimir.COMANDA :=comanda;
                      imprimir.CLIENTE :=cliente;
                      imprimir.ID_PAINEL :=StrToInt(idpainel);
                      imprimir.MESA :=mesa;
                      imprimir.Imprimir(erro);
                      imprimir.Free;




                        body.Free;

                        if erro <> '' then
                            raise Exception.Create(erro);

                    except on ex:exception do
                        begin

                              Lid:=TJSONArray.Create;
                         objeto := TJSONObject.Create;
                         objeto.AddPair('executado','erro 400');

                         Lid.Add(objeto);
                         Res.Send<TJSONArray>(Lid);
                                res.Send(ex.Message).Status(400);
                            exit;

                        end;
                    end;

                finally
                         Lid:=TJSONArray.Create;
                         objeto := TJSONObject.Create;
                         objeto.AddPair('executado','sucess');

                         Lid.Add(objeto);
                         Res.Send<TJSONArray>(Lid);


                end;
end;
procedure lanca_comanda(Req: THorseRequest; Res: THorseResponse; Next: TProc);
 var
query_comanda : TFDQuery;
Query_PAINEL : TFDQuery;
objeto: TJSONObject;
LComanda  : TJSONArray;
conexao : TFDConnection;
file_config : TInifile;

BEGIN
     if FileExists(ExtractFilePath(ParamStr(0))+'config.dll') then
       begin
                file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');






                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();
                   query_comanda:=TFDQuery.Create(NIL);
                   query_comanda.Connection:=conexao;
                   query_comanda.Close;

         query_comanda.SQL.Text:='select first 1 clientes.nome, ' +
                                             'comanda_cli.id id_comanda, '+
                                             'clientes.id_cliente ' +
                                             'from clientes   ' +
                                             'left join comanda_cli '+
                                             'on (comanda_cli.id_cliente = clientes.id_cliente '+
                                             'and (comanda_cli.tipo = 1 or  (comanda_cli.status = 1 '+
                                             'or comanda_cli.status = 0))) ' +
                                             'WHERE comanda_cli.COMANDA =:comanda '+
                                             'and comanda_cli.status = 1';

           query_comanda.ParamByName('comanda').AsString :=retirarZeros(Req.Params['comanda']);
           query_comanda.open;
           LComanda     := TJSONArray.Create;



           if query_comanda.recordcount > 0 then
             begin
                     objeto := TJSONObject.Create;
                     if Req.Params['tipo'] = '0' then
                    begin
                     Query_PAINEL:=TFDQuery.Create(nil);
                     Query_PAINEL.Connection:=conexao;
                     Query_PAINEL.close;
                     Query_PAINEL.SQL.Text:='select gen_id(COMANDA_PAINEL_ID,1) FROM RDB$DATABASE';
                     Query_PAINEL.OPEN;

                     objeto.AddPair('id_lanca',IntToStr(Query_PAINEL.FieldByName('gen_id').AsInteger));
                     objeto.AddPair('id_cliente',query_comanda.FieldByName('id_cliente').AsString);
                     objeto.AddPair('nome',query_comanda.FieldByName('nome').AsString);
                     objeto.AddPair('id_comanda',query_comanda.FieldByName('id_comanda').AsString);
                      LComanda.Add(objeto);
                    end
                    else
                    begin
                      objeto.AddPair('id_lanca','0');
                     objeto.AddPair('id_cliente',query_comanda.FieldByName('id_cliente').AsString);
                     objeto.AddPair('nome',query_comanda.FieldByName('nome').AsString);
                     objeto.AddPair('id_comanda',query_comanda.FieldByName('id_comanda').AsString);
                      LComanda.Add(objeto);
                    end;
                      Res.Send<TJSONArray>(LComanda);

             end;


           query_comanda.FREE;
           conexao.Free;
           file_config.Free;

       end;
END;


procedure lanca_produto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
query_produtos : TFDQuery;
objeto: TJSONObject;
LProdutos  : TJSONArray;
conexao : TFDConnection;
file_config : TInifile;
codigoB : string;
BEGIN
     if FileExists(ExtractFilePath(ParamStr(0))+'config.dll') then
       begin
                file_config:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'config.dll');






                   conexao:=TFDConnection.Create(NIL);
                   conexao.DriverName:= 'FB';
                   conexao.Params.Values['DataBase'] :=file_config.ReadString(IntToStr(0),'SERVIDOR','')+':'+file_config.ReadString(IntToStr(0),'BD','');
                   conexao.Params.Add('user_name='+file_config.ReadString(IntToStr(0),'USER',''));
                   conexao.Params.Add('password='+CRYPT('D',file_config.ReadString(IntToStr(0),'PASSWORD','')));
                   conexao.Open();
                   query_produtos:=TFDQuery.Create(NIL);
                   query_produtos.Connection:=conexao;
                   query_produtos.Close;

                     Query_PRODUTOS.SQL.Text:='select produtos.id_produto, '+
                                              'produtos.codigo_barra, '+
                                              'produtos.descricao, '+
                                              'produtos.unidade, '+
                                              'coalesce(app_categoria.id_impressora,0) id_impressora, '+
                                              'coalesce(categorias.classificacao,''0'')classificacao ' +
                                              'from produtos ' +
                                              'left join categorias on categorias.id_categoria = produtos.id_categoria ' +
                                              'left join app_categoria on app_categoria.id_appcategoria = categorias.classificacao '+
                                              'where produtos.codigo_barra =:a';

                     Query_PRODUTOS.ParamByName('a').AsString :=Req.Params['codigo_barras'];
                     Query_PRODUTOS.open;




                        LProdutos     := TJSONArray.Create;
                      if query_produtos.RecordCount >0 then
                       begin
                        query_produtos.first;
                        while NOT QUERY_PRODUTOS.Eof do
                        BEGIN
                         objeto := TJSONObject.Create;
                         objeto.AddPair('id_produto',query_produtos.FieldByName('ID_PRODUTO').AsString);
                         objeto.AddPair('descricao',query_produtos.FieldByName('DESCRICAO').AsString);
                         objeto.AddPair('codigo_barras',Query_PRODUTOS.FieldByName('CODIGO_BARRA').AsString);
                         objeto.AddPair('unidade',Query_PRODUTOS.FieldByName('unidade').AsString);
                         objeto.AddPair('classificacao',Query_PRODUTOS.FieldByName('CLASSIFICACAO').AsString);
                         objeto.AddPair('impressora',Query_PRODUTOS.FieldByName('id_impressora').AsString);
                         LProdutos.Add(objeto);
                         query_produtos.NEXT;
                        END;
                       end;


                        Res.Send<TJSONArray>(LProdutos);
                        query_produtos.FREE;
                        conexao.Free;
                        file_config.Free;




       end;


end;

end.
