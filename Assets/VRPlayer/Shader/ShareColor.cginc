static const float bright = 1.015;
static const float3 sft_pos = {1.12, 1.09, 1.185};
static const float3 sft_neg = {1.12, 1.09, 1.185};
static const float saturation = 0.99;
static const float sr = (1. - saturation) * 0.2125;
static const float sg = (1. - saturation) * 0.7154;
static const float sb = (1. - saturation) * 0.0721;
static const float3x3 saturationMatrix = float3x3(sr + saturation, sg, sb,
sr, sg+saturation, sb,
sr, sg, sb+saturation);

// uniform float saturation;
// uniform float4x4 saturationMatrix;
// uniform float bright;
// uniform float4 sft_pos;
// uniform float4 sft_neg;

float3 colorShift(float3 color) {
	float p_mean = (color.r + color.g + color.b) * 0.3333333;
	float3 p_diff = color - p_mean;
	float3 mask = step(0., p_diff);
	float3 p_ce = p_diff * (mask * sft_pos + (1. - mask) * sft_neg) + p_mean;
	p_ce *= bright;
	p_ce = clamp(mul(p_ce, (float3x3)saturationMatrix), 0., 1.);
	return p_ce;
}
