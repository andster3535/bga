(* ***** BEGIN LICENSE BLOCK *****
 * Version: GNU GPL 2.0
 *
 * The contents of this file are subject to the
 * GNU General Public License Version 2.0; you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * http://www.gnu.org/licenses/gpl.html
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is GuiRFASettings (http://code.google.com/p/bga)
 *
 * The Initial Developer of the Original Code is
 * Yann Papouin <yann.papouin at @ gmail.com>
 *
 * ***** END LICENSE BLOCK ***** *)

unit GuiRFASettings;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, ValEdit, SpTBXItem, SpTBXControls;

type
  TRFASettingsForm = class(TForm)
    SpTBXGroupBox1: TSpTBXGroupBox;
    ValueListEditor1: TValueListEditor;
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
    function GetProgramByExt(Ext : string) : string;
  end;

var
  RFASettingsForm: TRFASettingsForm;

implementation

{$R *.dfm}

{ TRFASettingsForm }

function TRFASettingsForm.GetProgramByExt(Ext: string): string;
begin
  result := EmptyStr;
end;

end.
