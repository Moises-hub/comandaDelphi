program coliseucomanda;

uses
  Vcl.SvcMgr,
  Horse,
  Horse.Jhonson,
  UFrmPrincipal in 'UFrmPrincipal.pas' {Coliseu_Comanda: TService},
  UController in '..\controller\UController.pas',
  UImprimir in '..\controller\UImprimir.pas',
  ULancamento in '..\controller\ULancamento.pas',
  UFrmImagem in 'UFrmImagem.pas' {FrmImagem};

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TColiseu_Comanda, Coliseu_Comanda);
  Application.CreateForm(TFrmImagem, FrmImagem);
  UCONTROLLER.Registry;
  THorse.Use(Jhonson());
  THorse.Listen(8181);
  Application.Run;
end.
