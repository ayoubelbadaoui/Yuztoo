import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class PosteHistorique {
  const PosteHistorique({
    this.codeCnp,
    this.dateDebut,
    this.dateFin,
    this.titrePoste,
  });
  final String? codeCnp;
  final String? dateDebut;
  final String? dateFin;
  final String? titrePoste;
}

class EmploiRecord {
  const EmploiRecord({
    required this.employeur,
    required this.dateDebut,
    required this.dateFin,
    this.changementPoste = false,
    this.heuresParSemaine,
    this.nbPostes,
    this.pays,
    this.ville,
    this.titrePoste,
    this.postes = const [],
  });
  final String employeur;
  final String dateDebut;
  final String dateFin;
  final bool changementPoste;
  final int? heuresParSemaine;
  final int? nbPostes;
  final String? pays;
  final String? ville;
  final String? titrePoste;
  final List<PosteHistorique> postes;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class EmploymentHistoryScreen extends StatefulWidget {
  const EmploymentHistoryScreen({
    super.key,
    required this.emplois,
    this.onBack,
  });

  final List<EmploiRecord> emplois;
  final VoidCallback? onBack;

  @override
  State<EmploymentHistoryScreen> createState() =>
      _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState extends State<EmploymentHistoryScreen> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _Pal.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _Pal.bg,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _EmploiCard(
                    record: widget.emplois[i],
                    index: i,
                    total: widget.emplois.length,
                    isLast: i == widget.emplois.length - 1,
                    isExpanded: _expanded.contains(i),
                    onToggle: () => setState(() {
                      _expanded.contains(i)
                          ? _expanded.remove(i)
                          : _expanded.add(i);
                    }),
                  ),
                  childCount: widget.emplois.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: _Pal.navy,
      leading: widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: widget.onBack,
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_Pal.navyDark, _Pal.navy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.work_history_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historique des emplois',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${widget.emplois.length} emploi${widget.emplois.length > 1 ? 's' : ''} enregistré${widget.emplois.length > 1 ? 's' : ''}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Historique des emplois',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Emploi Card ─────────────────────────────────────────────────────────────

class _EmploiCard extends StatelessWidget {
  const _EmploiCard({
    required this.record,
    required this.index,
    required this.total,
    required this.isLast,
    required this.isExpanded,
    required this.onToggle,
  });

  final EmploiRecord record;
  final int index;
  final int total;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline column
        SizedBox(
          width: 40,
          child: Column(
            children: [
              const SizedBox(height: 18),
              _TimelineDot(active: index == total - 1),
              if (!isLast)
                Container(
                  width: 2,
                  height: double.infinity,
                  color: _Pal.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // ── Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: _Pal.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isExpanded ? _Pal.accent : _Pal.border,
                    width: isExpanded ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: isExpanded ? 20 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _CardHeader(record: record, isExpanded: isExpanded),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _CardBody(record: record),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _Pal.accent : _Pal.border,
        border: Border.all(color: _Pal.bg, width: 2),
        boxShadow: active
            ? [
                BoxShadow(
                  color: _Pal.accent.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );
  }
}

// ─── Card Header ─────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.record, required this.isExpanded});
  final EmploiRecord record;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final duration = _calcDuration(record.dateDebut, record.dateFin);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Company avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_Pal.navy, Color(0xFF1A3A5C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    record.employeur.isNotEmpty
                        ? record.employeur[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.employeur,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (record.titrePoste != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.titrePoste!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _Pal.textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _Pal.textSub,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date range + duration
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: _Pal.textSub),
              const SizedBox(width: 6),
              Text(
                '${_fmt(record.dateDebut)} → ${_fmt(record.dateFin)}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: _Pal.textSub,
                ),
              ),
              const Spacer(),
              if (duration != null)
                _Chip(label: duration, color: _Pal.accent),
            ],
          ),
          if (record.pays != null || record.ville != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: _Pal.textSub),
                const SizedBox(width: 6),
                Text(
                  [if (record.ville != null) record.ville!, if (record.pays != null) record.pays!]
                      .join(', '),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: _Pal.textSub,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(String iso) {
    final p = iso.split('-');
    if (p.length < 3) return iso;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  String? _calcDuration(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final months = (e.year - s.year) * 12 + (e.month - s.month);
      final y = months ~/ 12;
      final m = months % 12;
      if (y > 0 && m > 0) return '${y}a ${m}m';
      if (y > 0) return '$y an${y > 1 ? 's' : ''}';
      return '$m mois';
    } catch (_) {
      return null;
    }
  }
}

// ─── Card Body ────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.record});
  final EmploiRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Divider(),
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              if (record.heuresParSemaine != null)
                Expanded(
                  child: _StatTile(
                    icon: Icons.access_time_rounded,
                    label: 'H/semaine',
                    value: '${record.heuresParSemaine}h',
                  ),
                ),
              if (record.nbPostes != null)
                Expanded(
                  child: _StatTile(
                    icon: Icons.work_outline_rounded,
                    label: 'Nb postes',
                    value: '${record.nbPostes}',
                  ),
                ),
              Expanded(
                child: _StatTile(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Changement',
                  value: record.changementPoste ? 'Oui' : 'Non',
                  valueColor: record.changementPoste
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          // Sub-positions timeline
          if (record.postes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Postes occupés',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Pal.textSub,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...record.postes.asMap().entries.map((e) => _PosteRow(
                  poste: e.value,
                  index: e.key,
                  isLast: e.key == record.postes.length - 1,
                )),
          ],
        ],
      ),
    );
  }
}

class _PosteRow extends StatelessWidget {
  const _PosteRow({
    required this.poste,
    required this.index,
    required this.isLast,
  });
  final PosteHistorique poste;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final title = poste.titrePoste ?? 'Poste ${index + 1}';
    final period = (poste.dateDebut != null && poste.dateFin != null)
        ? '${_fmt(poste.dateDebut!)} → ${_fmt(poste.dateFin!)}'
        : null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Pal.accent,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: _Pal.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _Pal.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Pal.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (period != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        period,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: _Pal.textSub,
                        ),
                      ),
                    ],
                    if (poste.codeCnp != null) ...[
                      const SizedBox(height: 4),
                      _Chip(label: 'CNP: ${poste.codeCnp!}', color: _Pal.navy),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String iso) {
    final p = iso.split('-');
    if (p.length < 3) return iso;
    return '${p[2]}/${p[1]}/${p[0]}';
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _Pal.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Pal.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: _Pal.accent),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: _Pal.textSub,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color == _Pal.navy ? Colors.white70 : color,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _Pal.border);
}

// ─── Palette ─────────────────────────────────────────────────────────────────

abstract final class _Pal {
  static const bg = Color(0xFF0E1A2B);
  static const navyDark = Color(0xFF060F1A);
  static const navy = Color(0xFF0E2A44);
  static const card = Color(0xFF142233);
  static const border = Color(0xFF1E3048);
  static const accent = Color(0xFF3B82F6);
  static const textSub = Color(0xFF6B8CAE);
}
