{ *************************************************************************** }
{                                                                             }
{ NLDSnapPanel  -  www.nldelphi.com Open Source designtime component          }
{                                                                             }
{ Initiator: Albert de Weerd (aka NGLN)                                       }
{ License: Free to use, free to modify                                        }
{ SVN path: http://svn.nldelphi.com/nldelphi/opensource/ngln/NLDSnapPanel     }
{                                                                             }
{ *************************************************************************** }
{                                                                             }
{ Edit by: Albert de Weerd                                                    }
{ Date: May 23, 2008                                                          }
{ Version: 1.0.0.0                                                            }
{                                                                             }
{ *************************************************************************** }

unit NLDSnapPanel;

interface

uses
  Windows, Classes, Graphics, ExtCtrls, Messages, Controls, Buttons;

const
  DefMaxWidth = 105;
  DefMinWidth = 5;

type
  TNLDSnapPanel = class(TCustomPanel)
  private
    FAutoHide: Boolean;
    FGhostWin: TWinControl;
    FMaxWidth: Integer;
    FMinWidth: Integer;
    FMouseCaptured: Boolean;
    FPinButton: TSpeedButton;
    FPinButtonDownHint: String;
    FPinButtonUpHint: String;
    FTimer: TTimer;
    FUnhiding: Boolean;
    function GetShowHint: Boolean;
    function GetWidth: Integer;
    function IsShowHintStored: Boolean;
    procedure PinButtonClick(Sender: TObject);
    procedure SetAutoHide(const Value: Boolean);
    procedure SetMinWidth(const Value: Integer);
    procedure SetPinButtonDownHint(const Value: String);
    procedure SetPinButtonUpHint(const Value: String);
    procedure SetShowHint(const Value: Boolean);
    procedure SetWidth(const Value: Integer);
    procedure Timer(Sender: TObject);
    procedure UpdatePinButtonHint;
    procedure CMControlListChange(var Message: TCMControlListChange);
      message CM_CONTROLLISTCHANGE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure Paint; override;
    procedure SetParent(AParent: TWinControl); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property AutoHide: Boolean read FAutoHide write SetAutoHide default False;
    property MinWidth: Integer read FMinWidth write SetMinWidth
      default DefMinWidth;
    property PinButtonDownHint: String read FPinButtonDownHint
      write SetPinButtonDownHint;
    property PinButtonUpHint: String read FPinButtonUpHint
      write SetPinButtonUpHint;
    property ShowHint: Boolean read GetShowHint write SetShowHint
      stored IsShowHintStored;
    property Width: Integer read GetWidth write SetWidth default DefMaxWidth;
  published
    property Alignment default taLeftJustify;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BorderWidth;
    property BorderStyle;
    property Caption;
    property Color;
    property Font;
    property Hint;
    property ParentBackground;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property TabOrder;
    property Visible;
  end;

procedure Register;

implementation

{$R *.res}

uses
  Math, Themes;

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDSnapPanel]);
end;

{ TNLDSnapPanel }

resourcestring
  SPinButtonBmpResName = 'PINBUTTON';

const
  DefPinButtonSize = 20;
  DefPinButtonMargin = 3;
  DefResizeStep = 15;
  DefTimerInterval = 20;

procedure TNLDSnapPanel.AdjustClientRect(var Rect: TRect);
begin
  inherited AdjustClientRect(Rect);
  Inc(Rect.Top, DefPinButtonSize + 2 * DefPinButtonMargin);
end;

procedure TNLDSnapPanel.CMControlListChange(
  var Message: TCMControlListChange);
begin
  if Message.Inserting then
    with Message.Control do
      Anchors := Anchors - [akLeft] + [akRight];
end;

procedure TNLDSnapPanel.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if FAutoHide then
    if not FMouseCaptured then
    begin
      FMouseCaptured := True;
      FUnhiding := True;
      FTimer.Enabled := True;
    end;
end;

procedure TNLDSnapPanel.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FAutoHide then
  begin
    FMouseCaptured := PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos));
    if not FMouseCaptured then
    begin
      FUnhiding := False;
      FTimer.Enabled := True;
    end;
  end;
end;

constructor TNLDSnapPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaxWidth := DefMaxWidth;
  FMinWidth := DefMinWidth;
  Alignment := taLeftJustify;
  Align := alLeft;
  Left := 0;
  Top := 0;
  inherited Width := FMaxWidth;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := DefTimerInterval;
  FTimer.OnTimer := Timer;
  FPinButton := TSpeedButton.Create(Self);
  FPinButton.Glyph.LoadFromResourceName(HInstance, SPinButtonBmpResName);
  FPinButton.GroupIndex := -1;
  FPinButton.AllowAllUp := True;
  FPinButton.Down := True;
  FPinButton.Anchors := [akTop, akRight];
  FPinButton.SetBounds(DefMaxWidth - DefPinButtonSize - FMinWidth,
    DefPinButtonMargin, DefPinButtonSize, DefPinButtonSize);
  FPinButton.OnClick := PinButtonClick;
  FPinButton.Parent := Self;
end;

function TNLDSnapPanel.GetShowHint: Boolean;
begin
  Result := inherited ShowHint;
end;

function TNLDSnapPanel.GetWidth: Integer;
begin
  Result := inherited Width;
end;

function TNLDSnapPanel.IsShowHintStored: Boolean;
begin
  Result := not ParentShowHint;
end;

procedure TNLDSnapPanel.Paint;
const
  Alignments: array[TAlignment] of Longint = (DT_LEFT, DT_RIGHT, DT_CENTER);
var
  Rect: TRect;
  TopColor, BottomColor: TColor;
  FontHeight: Integer;
  Flags: Longint;

  procedure AdjustColors(Bevel: TPanelBevel);
  begin
    TopColor := clBtnHighlight;
    if Bevel = bvLowered then TopColor := clBtnShadow;
    BottomColor := clBtnShadow;
    if Bevel = bvLowered then BottomColor := clBtnHighlight;
  end;

begin
  Rect := GetClientRect;
  if BevelOuter <> bvNone then
  begin
    AdjustColors(BevelOuter);
    Frame3D(Canvas, Rect, TopColor, BottomColor, BevelWidth);
  end;
  Frame3D(Canvas, Rect, Color, Color, BorderWidth);
  if BevelInner <> bvNone then
  begin
    AdjustColors(BevelInner);
    Frame3D(Canvas, Rect, TopColor, BottomColor, BevelWidth);
  end;
  with Canvas do
  begin
    if not ThemeServices.ThemesEnabled or not ParentBackground then
    begin
      Brush.Color := Color;
      FillRect(Rect);
    end;
    Brush.Style := bsClear;
    Font := Self.Font;
    FontHeight := TextHeight('W');
    with Rect do
    begin
      Left := Width - FMaxWidth + FMinWidth;
      Top := 5;
      Bottom := Top + FontHeight;
      Right := Width - DefPinButtonSize - FMinWidth - 5;
    end;
    Flags := DT_EXPANDTABS or Alignments[Alignment];
    Flags := DrawTextBiDiModeFlags(Flags);
    DrawText(Handle, PChar(Caption), -1, Rect, Flags);
    Pen.Color := clBtnShadow;
    MoveTo(Rect.Left, Rect.Bottom + DefPinButtonMargin);
    LineTo(Rect.Right, PenPos.Y);
  end;
end;

procedure TNLDSnapPanel.PinButtonClick(Sender: TObject);
begin
  AutoHide := not FPinButton.Down;
end;

procedure TNLDSnapPanel.SetAutoHide(const Value: Boolean);
begin
  if FAutoHide <> Value then
  begin
    FAutoHide := Value;
    FPinButton.Down := not FAutoHide;
    if FAutoHide then
    begin
      Align := alNone;
      Anchors := [akLeft, akTop, akBottom];
      FGhostWin := TWinControl.Create(Self);
      FGhostWin.Align := alLeft;
      FGhostWin.Width := FMinWidth;
      FGhostWin.Parent := Parent;
      FGhostWin.SendToBack;
    end
    else
    begin
      Align := alLeft;
      FGhostWin.Free;
      FGhostWin := nil;
    end;
    UpdatePinButtonHint;
  end;
end;

procedure TNLDSnapPanel.SetMinWidth(const Value: Integer);
begin
  if FMinWidth <> Value then
  begin
    FPinButton.Left := FPinButton.Left + FMinWidth - Value;
    FMinWidth := Value;
    if FAutoHide and not FUnhiding then
    begin
      inherited Width := FMinWidth;
      FGhostWin.Width := FMinWidth;
    end;
  end;
end;

procedure TNLDSnapPanel.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if FGhostWin <> nil then
  begin
    FGhostWin.Parent := AParent;
    FGhostWin.SendToBack;
  end;
end;

procedure TNLDSnapPanel.SetPinButtonDownHint(const Value: String);
begin
  if FPinButtonDownHint <> Value then
  begin
    FPinButtonDownHint := Value;
    UpdatePinButtonHint;
  end;
end;

procedure TNLDSnapPanel.SetPinButtonUpHint(const Value: String);
begin
  if FPinButtonUpHint <> Value then
  begin
    FPinButtonUpHint := Value;
    UpdatePinButtonHint;
  end;
end;

procedure TNLDSnapPanel.SetShowHint(const Value: Boolean);
begin
  inherited ShowHint := Value;
  FPinButton.ShowHint := Value;
end;

procedure TNLDSnapPanel.SetWidth(const Value: Integer);
begin
  if FMaxWidth <> Value then
  begin
    FMaxWidth := Value;
    if not FAutoHide then
      inherited Width := FMaxWidth;
  end;
end;

procedure TNLDSnapPanel.Timer(Sender: TObject);
var
  CalcWidth: Integer;
begin
  if FUnhiding then
    CalcWidth := Width + DefResizeStep
  else
    CalcWidth := Width - DefResizeStep;
  inherited Width := Max(FMinWidth, Min(CalcWidth, FMaxWidth));
  if (Width = FMinWidth) or (Width = FMaxWidth) then
    FTimer.Enabled := False;
end;

procedure TNLDSnapPanel.UpdatePinButtonHint;
begin
  if FPinButton.Down then
    FPinButton.Hint := FPinButtonDownHint
  else
    FPinButton.Hint := FPinButtonUpHint;
end;

end.
