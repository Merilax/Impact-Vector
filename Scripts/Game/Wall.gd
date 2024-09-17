extends StaticBody2D

func hit(node):
	if node.is_in_group('Ball'):
		$'HitSound'.play()