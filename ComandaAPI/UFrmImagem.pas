unit UFrmImagem;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,  Vcl.ExtCtrls, dxGDIPlusClasses;

type
  TFrmImagem = class(TForm)
    Image2: TImage;
    Image1: TImage;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmImagem: TFrmImagem;

implementation

{$R *.dfm}

end.
