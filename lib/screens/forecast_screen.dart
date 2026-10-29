import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/app_settings.dart';
import '../utils/format.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({required this.report, super.key});

  final WeatherReport report;

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with SettingsListener<ForecastScreen> {
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final hourly = [
      for (var i = 0; i < report.hours.length; i++)
        (
          i == 0 ? 'Now' : hourLabel(report.hours[i].time),
          degrees(report.hours[i].tempC),
          '${report.hours[i].chanceOfRain}%',
          weatherIcon(report.hours[i].conditionCode, isDay: report.hours[i].isDay),
        ),
    ];
    final days = [
      for (final day in report.days)
        (
          weekdays[day.date.weekday - 1],
          '${day.date.day} ${months[day.date.month - 1]}',
          day.condition,
          degrees(day.minC),
          degrees(day.maxC),
          '${day.chanceOfRain}%',
          weatherIcon(day.conditionCode),
        ),
    ];
    // Every third hour keeps the chart readable across the next 24 hours.
    final chartHours = [
      for (var i = 0; i < report.hours.length; i += 3) report.hours[i],
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Forecast',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '${report.city}, ${report.country}',
              style: const TextStyle(
                color: Color(0xFF7185A6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(
              Icons.location_on_rounded,
              color: Color(0xFF63B8FF),
              size: 20,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            _SegmentedControl(
              selected: _view,
              onChanged: (value) => setState(() => _view = value),
            ),
            const SizedBox(height: 24),
            if (_view == 0) ...[
              const _SectionTitle(title: 'Hourly forecast'),
              const SizedBox(height: 12),
              _HourlyRail(items: hourly),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Temperature next 24 hours'),
              const SizedBox(height: 12),
              _TemperatureChart(hours: chartHours),
            ] else ...[
              const _SectionTitle(title: '5-day forecast'),
              const SizedBox(height: 12),
              _DayForecastList(days: days),
            ],
            const SizedBox(height: 24),
            _WeatherSummary(report: report),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Weather metrics'),
            const SizedBox(height: 12),
            _MetricsGrid(report: report),
          ],
        ),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Hourly',
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
          _Segment(
            label: '5 Days',
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x120F2848),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).hintColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _HourlyRail extends StatelessWidget {
  const _HourlyRail({required this.items});

  final List<(String, String, String, IconData)> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 146,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final current = index == 0;
          return Container(
            width: 75,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: current ? const Color(0xFF5BA9E8) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: current ? Colors.transparent : Theme.of(context).dividerColor,
              ),
              boxShadow: current
                  ? const [
                      BoxShadow(
                        color: Color(0x355BA9E8),
                        blurRadius: 13,
                        offset: Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.$1,
                  style: TextStyle(
                    color: current ? Colors.white : Theme.of(context).hintColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  item.$4,
                  color: current
                      ? const Color(0xFFFFD477)
                      : const Color(0xFF63B8FF),
                  size: 25,
                ),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: current ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.$3} rain',
                  style: TextStyle(
                    color: current
                        ? const Color(0xE6FFFFFF)
                    : Theme.of(context).hintColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TemperatureChart extends StatelessWidget {
  const _TemperatureChart({required this.hours});

  final List<HourForecast> hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 225,
      padding: const EdgeInsets.fromLTRB(13, 17, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: CustomPaint(
        painter: _ChartPainter(
          values: [for (final hour in hours) hour.tempC],
          labels: [
            for (var i = 0; i < hours.length; i++)
              i == 0 ? 'Now' : hourLabel(hours[i].time),
          ],
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0;
    const right = 6.0;
    const top = 10.0;
    const bottom = 28.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    if (values.length < 2) return;
    var minValue = values.reduce((a, b) => a < b ? a : b).floorToDouble();
    var maxValue = values.reduce((a, b) => a > b ? a : b).ceilToDouble();
    if (maxValue - minValue < 3) {
      minValue -= 1;
      maxValue += 2;
    }
    final range = maxValue - minValue;
    final gridLabels = [
      for (var i = 0; i < 4; i++) degrees(maxValue - range * i / 3),
    ];
    final gridPaint = Paint()
      ..color = const Color(0xFFEAF0F7)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF4D9BD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = left + chartWidth * index / (values.length - 1);
      final y = top + (maxValue - values[index]) / range * chartHeight;
      points.add(Offset(x, y));
    }
    for (var index = 0; index < 4; index++) {
      final y = top + chartHeight * index / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        gridLabels[index],
        Offset(0, y - 7),
        const TextStyle(color: Color(0xFF91A0B4), fontSize: 10),
      );
    }
    final fillPath = Path()..moveTo(points.first.dx, top + chartHeight);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, top + chartHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x4063B8FF), Color(0x0563B8FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, top, size.width, chartHeight)),
    );
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(linePath, linePaint);
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        points[index],
        3,
        Paint()..color = const Color(0xFF4D9BD8),
      );
      _drawText(
        canvas,
        labels[index],
        Offset(points[index].dx - 15, size.height - 19),
        const TextStyle(color: Color(0xFF8290A8), fontSize: 9),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.labels != labels;
}

class _DayForecastList extends StatelessWidget {
  const _DayForecastList({required this.days});

  final List<(String, String, String, String, String, String, IconData)> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            _DayRow(
              day: days[index].$1,
              date: days[index].$2,
              condition: days[index].$3,
              low: days[index].$4,
              high: days[index].$5,
              rain: days[index].$6,
              icon: days[index].$7,
            ),
            if (index < days.length - 1)
              Divider(height: 1, color: Theme.of(context).dividerColor),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.date,
    required this.condition,
    required this.low,
    required this.high,
    required this.rain,
    required this.icon,
  });

  final String day;
  final String date;
  final String condition;
  final String low;
  final String high;
  final String rain;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF8290A8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFF63B8FF), size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rain rain',
                  style: const TextStyle(
                    color: Color(0xFF8290A8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            low,
            style: const TextStyle(
              color: Color(0xFF8290A8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            high,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherSummary extends StatelessWidget {
  const _WeatherSummary({required this.report});

  final WeatherReport report;

  String get _text {
    final today = report.today;
    final base =
        'Currently ${degrees(report.tempC)} and ${report.condition.toLowerCase()} in ${report.city}.';
    if (today == null) return base;
    return '$base Today expect a high of ${degrees(today.maxC)} and a low of '
        '${degrees(today.minC)}, with a ${today.chanceOfRain}% chance of rain.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFD8ECFB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF4D9BD8),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _text,
              style: const TextStyle(
                color: Color(0xFF31537F),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: 'Humidity',
            value: '${report.humidity}%',
            icon: Icons.water_drop_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            label: 'Wind speed',
            value: wind(report.windKph),
            icon: Icons.air_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            label: 'Rain',
            value: rain(report.precipMm),
            icon: Icons.grain_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            label: 'UV index',
            value: report.uv.round().toString(),
            icon: Icons.wb_sunny_outlined,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: const Color(0xFF63B8FF), size: 19),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8290A8), fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
