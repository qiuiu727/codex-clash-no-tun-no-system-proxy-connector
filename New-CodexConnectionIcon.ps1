[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot 'CodexConnection.ico'
}
Add-Type -AssemblyName System.Drawing

$source = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CodexConnectionIcon
{
    private static GraphicsPath RoundedRect(RectangleF bounds, float radius)
    {
        float diameter = radius * 2f;
        GraphicsPath path = new GraphicsPath();
        path.AddArc(bounds.X, bounds.Y, diameter, diameter, 180, 90);
        path.AddArc(bounds.Right - diameter, bounds.Y, diameter, diameter, 270, 90);
        path.AddArc(bounds.Right - diameter, bounds.Bottom - diameter, diameter, diameter, 0, 90);
        path.AddArc(bounds.X, bounds.Bottom - diameter, diameter, diameter, 90, 90);
        path.CloseFigure();
        return path;
    }

    public static Bitmap Draw(int size)
    {
        Bitmap bitmap = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics graphics = Graphics.FromImage(bitmap))
        {
            graphics.SmoothingMode = SmoothingMode.AntiAlias;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            float unit = size / 128f;
            RectangleF card = new RectangleF(8f * unit, 8f * unit, 112f * unit, 112f * unit);
            using (GraphicsPath cardPath = RoundedRect(card, 25f * unit))
            using (LinearGradientBrush background = new LinearGradientBrush(card, Color.FromArgb(19, 30, 51), Color.FromArgb(30, 54, 86), 45f))
            {
                graphics.FillPath(background, cardPath);
            }

            using (Pen border = new Pen(Color.FromArgb(77, 213, 240), Math.Max(1f, 2f * unit)))
            using (GraphicsPath cardPath = RoundedRect(card, 25f * unit))
            {
                graphics.DrawPath(border, cardPath);
            }

            using (Pen code = new Pen(Color.FromArgb(104, 220, 238), Math.Max(2f, 7f * unit)))
            {
                code.StartCap = LineCap.Round;
                code.EndCap = LineCap.Round;
                graphics.DrawLines(code, new PointF[] {
                    new PointF(48f * unit, 43f * unit), new PointF(31f * unit, 64f * unit), new PointF(48f * unit, 85f * unit)
                });
                graphics.DrawLines(code, new PointF[] {
                    new PointF(68f * unit, 43f * unit), new PointF(85f * unit, 64f * unit), new PointF(68f * unit, 85f * unit)
                });
            }

            using (Pen connection = new Pen(Color.FromArgb(117, 238, 183), Math.Max(1f, 3f * unit)))
            using (SolidBrush node = new SolidBrush(Color.FromArgb(117, 238, 183)))
            {
                connection.StartCap = LineCap.Round;
                connection.EndCap = LineCap.Round;
                graphics.DrawLine(connection, 49f * unit, 100f * unit, 79f * unit, 100f * unit);
                graphics.FillEllipse(node, 42f * unit, 93f * unit, 14f * unit, 14f * unit);
                graphics.FillEllipse(node, 72f * unit, 93f * unit, 14f * unit, 14f * unit);
            }

            using (SolidBrush arrow = new SolidBrush(Color.FromArgb(117, 238, 183)))
            {
                PointF[] points = new PointF[] {
                    new PointF(91f * unit, 53f * unit), new PointF(108f * unit, 64f * unit), new PointF(91f * unit, 75f * unit)
                };
                graphics.FillPolygon(arrow, points);
            }
        }
        return bitmap;
    }

    public static void WriteIcon(string path)
    {
        int[] sizes = new int[] { 16, 24, 32, 48, 64, 128, 256 };
        byte[][] images = new byte[sizes.Length][];
        for (int i = 0; i < sizes.Length; i++)
        {
            using (Bitmap bitmap = Draw(sizes[i]))
            using (MemoryStream stream = new MemoryStream())
            {
                bitmap.Save(stream, ImageFormat.Png);
                images[i] = stream.ToArray();
            }
        }

        using (FileStream stream = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None))
        using (BinaryWriter writer = new BinaryWriter(stream))
        {
            writer.Write((ushort)0);
            writer.Write((ushort)1);
            writer.Write((ushort)images.Length);
            int offset = 6 + (images.Length * 16);
            for (int i = 0; i < sizes.Length; i++)
            {
                int size = sizes[i];
                writer.Write((byte)(size == 256 ? 0 : size));
                writer.Write((byte)(size == 256 ? 0 : size));
                writer.Write((byte)0);
                writer.Write((byte)0);
                writer.Write((ushort)1);
                writer.Write((ushort)32);
                writer.Write(images[i].Length);
                writer.Write(offset);
                offset += images[i].Length;
            }
            for (int i = 0; i < images.Length; i++)
            {
                writer.Write(images[i]);
            }
        }
    }
}
'@

Add-Type -TypeDefinition $source -ReferencedAssemblies System.Drawing
[CodexConnectionIcon]::WriteIcon($OutputPath)
Write-Output "Created $OutputPath"
