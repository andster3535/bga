unit ExFilesystemViewerMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  TExFilesystemViewerMainForm = class(TForm)
    procedure FormActivate(Sender: TObject);
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  ExFilesystemViewerMainForm: TExFilesystemViewerMainForm;

implementation

{$R *.dfm}

uses
  GuiFsView;

procedure TExFilesystemViewerMainForm.FormActivate(Sender: TObject);
begin
  FSViewForm.ShowModal;
  Close;
end;

end.
