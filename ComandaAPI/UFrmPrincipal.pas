unit UFrmPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs;

type
  TColiseu_Comanda = class(TService)
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  Coliseu_Comanda: TColiseu_Comanda;

implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  Coliseu_Comanda.Controller(CtrlCode);
end;

function TColiseu_Comanda.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

end.
