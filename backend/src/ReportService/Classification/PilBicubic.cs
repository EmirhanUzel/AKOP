namespace ReportService.Classification;

// Pillow'un Image.resize(..., BICUBIC) algoritmasının (libImaging/Resample.c) 8 bit RGB karşılığı.
// Küçültürken çekirdek ölçek kadar genişler (antialias) ve katsayılar sabit noktalı tam sayıyla hesaplanır;
// sonucun Python ile aynı çıkması için bu ayrıntılar korunmalı.
public static class PilBicubic
{
    private const int PrecisionBits = 32 - 8 - 2;
    private const double Support = 2.0;
    private const double A = -0.5;

    public static byte[] ResizeHorizontal(byte[] input, int width, int height, int newWidth)
    {
        if (newWidth == width)
        {
            return input;
        }

        var (bounds, kernelSize, coefficients) = ComputeCoefficients(width, newWidth);
        var output = new byte[newWidth * height * 3];

        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < newWidth; x++)
            {
                var (start, count) = bounds[x];

                for (var channel = 0; channel < 3; channel++)
                {
                    var sum = 1 << (PrecisionBits - 1);

                    for (var k = 0; k < count; k++)
                    {
                        sum += input[(y * width + start + k) * 3 + channel] * coefficients[x * kernelSize + k];
                    }

                    output[(y * newWidth + x) * 3 + channel] = Clip(sum);
                }
            }
        }

        return output;
    }

    public static byte[] ResizeVertical(byte[] input, int width, int height, int newHeight)
    {
        if (newHeight == height)
        {
            return input;
        }

        var (bounds, kernelSize, coefficients) = ComputeCoefficients(height, newHeight);
        var output = new byte[width * newHeight * 3];

        for (var y = 0; y < newHeight; y++)
        {
            var (start, count) = bounds[y];

            for (var x = 0; x < width; x++)
            {
                for (var channel = 0; channel < 3; channel++)
                {
                    var sum = 1 << (PrecisionBits - 1);

                    for (var k = 0; k < count; k++)
                    {
                        sum += input[((start + k) * width + x) * 3 + channel] * coefficients[y * kernelSize + k];
                    }

                    output[(y * width + x) * 3 + channel] = Clip(sum);
                }
            }
        }

        return output;
    }

    private static double Filter(double x)
    {
        x = Math.Abs(x);

        if (x < 1.0)
        {
            return ((A + 2.0) * x - (A + 3.0)) * x * x + 1;
        }

        if (x < 2.0)
        {
            return (((x - 5) * x + 8) * x - 4) * A;
        }

        return 0.0;
    }

    // Resample.c: precompute_coeffs + normalize_coeffs_8bpc
    private static ((int Start, int Count)[] Bounds, int KernelSize, int[] Coefficients) ComputeCoefficients(
        int inSize, int outSize)
    {
        var scale = (double)inSize / outSize;
        var filterScale = Math.Max(scale, 1.0);
        var support = Support * filterScale;
        var kernelSize = (int)Math.Ceiling(support) * 2 + 1;

        var bounds = new (int, int)[outSize];
        var coefficients = new int[outSize * kernelSize];
        var weights = new double[kernelSize];

        for (var i = 0; i < outSize; i++)
        {
            var center = (i + 0.5) * scale;
            var inverseScale = 1.0 / filterScale;

            var start = Math.Max((int)(center - support + 0.5), 0);
            var count = Math.Min((int)(center + support + 0.5), inSize) - start;

            var total = 0.0;

            for (var k = 0; k < count; k++)
            {
                weights[k] = Filter((k + start - center + 0.5) * inverseScale);
                total += weights[k];
            }

            for (var k = 0; k < count; k++)
            {
                var weight = total != 0.0 ? weights[k] / total : weights[k];

                coefficients[i * kernelSize + k] = weight < 0
                    ? (int)(-0.5 + weight * (1 << PrecisionBits))
                    : (int)(0.5 + weight * (1 << PrecisionBits));
            }

            bounds[i] = (start, count);
        }

        return (bounds, kernelSize, coefficients);
    }

    private static byte Clip(int value)
    {
        var shifted = value >> PrecisionBits;

        return (byte)Math.Clamp(shifted, 0, 255);
    }
}
