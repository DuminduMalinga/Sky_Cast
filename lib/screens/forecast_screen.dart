import 'package:flutter/material.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  int _view = 0;

  static const _hourly = [
    ('Now', '29°', '20%', Icons.cloud_queue_rounded),
    ('11 AM', '30°', '18%', Icons.wb_sunny_rounded),
    ('12 PM', '31°', '15%', Icons.wb_sunny_rounded),
    ('1 PM', '32°', '12%', Icons.wb_sunny_rounded),
    ('2 PM', '32°', '20%', Icons.cloud_rounded),
    ('3 PM', '31°', '35%', Icons.cloud_queue_rounded),
    ('4 PM', '30°', '42%', Icons.grain_rounded),
    ('5 PM', '29°', '38%', Icons.water_drop_rounded),
  ];

  static const _days = [
    (
      'Tue',
      '23 Apr',
      'Partly cloudy',
      '25°',
      '32°',
      '20%',
      Icons.cloud_queue_rounded,
    ),
    ('Wed', '24 Apr', 'Sunny', '25°', '33°', '8%', Icons.wb_sunny_rounded),
    ('Thu', '25 Apr', 'Light rain', '24°', '30°', '55%', Icons.grain_rounded),
    (
      'Fri',
      '26 Apr',
      'Mostly sunny',
      '25°',
      '32°',
      '18%',
      Icons.wb_sunny_rounded,
    ),
    (
      'Sat',
      '27 Apr',
      'Scattered rain',
      '24°',
      '31°',
      '48%',
      Icons.water_drop_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Forecast',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              'Colombo, Sri Lanka',
              style: TextStyle(
                color: Color(0xFF7185A6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        actions: [
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
              _HourlyRail(items: _hourly),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Temperature today'),
              const SizedBox(height: 12),
              const _TemperatureChart(),
            ] else ...[
              const _SectionTitle(title: '5-day forecast'),
              const SizedBox(height: 12),
              _DayForecastList(days: _days),
            ],
            const SizedBox(height: 24),
            const _WeatherSummary(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Weather metrics'),
            const SizedBox(height: 12),
            const _MetricsGrid(),
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
        color: const Color(0xFFE6EDF6),
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
            color: selected ? Colors.white : Colors.transparent,
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
                  ? const Color(0xFF101B36)
                  : const Color(0xFF7890AD),
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
              color: current ? const Color(0xFF5BA9E8) : Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: current ? Colors.transparent : const Color(0xFFE1EAF4),
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
                    color: current ? Colors.white : const Color(0xFF7588A4),
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
                    color: current ? Colors.white : const Color(0xFF101B36),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.$3} rain',
                  style: TextStyle(
                    color: current
                        ? const Color(0xE6FFFFFF)
                        : const Color(0xFF8290A8),
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
  const _TemperatureChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 225,
      padding: const EdgeInsets.fromLTRB(13, 17, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1EAF4)),
      ),
      child: CustomPaint(
        painter: _ChartPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0;
    const right = 6.0;
    const top = 10.0;
    const bottom = 28.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    const values = [29.0, 30.0, 31.0, 32.0, 32.0, 31.0, 30.0, 29.0];
    const labels = [
      'Now',
      '11 AM',
      '12 PM',
      '1 PM',
      '2 PM',
      '3 PM',
      '4 PM',
      '5 PM',
    ];
    const gridLabels = ['33°', '31°', '29°', '27°'];
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
      final y = top + (33 - values[index]) / 6 * chartHeight;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DayForecastList extends StatelessWidget {
  const _DayForecastList({required this.days});

  final List<(String, String, String, String, String, String, IconData)> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1EAF4)),
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
              const Divider(height: 1, color: Color(0xFFEDF2F7)),
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
                  style: const TextStyle(
                    color: Color(0xFF101B36),
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
                  style: const TextStyle(
                    color: Color(0xFF101B36),
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
            style: const TextStyle(
              color: Color(0xFF101B36),
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
  const _WeatherSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFD8ECFB)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF4D9BD8), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'A warm and partly cloudy day ahead. Expect bright skies through the afternoon, with a small chance of light rain toward evening.',
              style: TextStyle(
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
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _Metric(
            label: 'Humidity',
            value: '78%',
            icon: Icons.water_drop_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _Metric(
            label: 'Wind speed',
            value: '14 km/h',
            icon: Icons.air_rounded,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _Metric(
            label: 'UV index',
            value: '6',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1EAF4)),
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
            style: const TextStyle(
              color: Color(0xFF101B36),
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
      style: const TextStyle(
        color: Color(0xFF101B36),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
